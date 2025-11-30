import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = "Semua";

  Stream<QuerySnapshot> getMenus() {
    if (selectedCategory == "Semua") {
      return FirebaseFirestore.instance.collection('menus').snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('menus')
          .where('category', isEqualTo: selectedCategory)
          .snapshots();
    }
  }

  Widget categoryButton(String category) {
    bool isSelected = selectedCategory == category;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedCategory = category;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        shape: StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
      child: Text(category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "E-Canteen Poliwangi",
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // Tombol Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              categoryButton("Semua"),
              const SizedBox(width: 10),
              categoryButton("Makanan"),
              const SizedBox(width: 10),
              categoryButton("Minuman"),
            ],
          ),

          const SizedBox(height: 15),

          // StreamBuilder untuk data menu
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getMenus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Terjadi kesalahan"));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Menu belum tersedia.",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var item = docs[index];
                    return ListTile(
                      leading: Image.network(
                        item['imageUrl'],
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                      title: Text(item['name']),
                      subtitle: Text("Rp ${item['price']}"),
                      trailing: ElevatedButton(
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('orders')
                              .add({
                            'menuId': item.id,
                            'name': item['name'],
                            'price': item['price'],
                            'timestamp': Timestamp.now(),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Pesanan berhasil dikirim")),
                          );
                        },
                        child: const Text("Pesan"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
