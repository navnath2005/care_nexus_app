import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LowStockPage extends StatelessWidget {
  const LowStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Low Stock Alerts"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // GET DATA: Filter products where quantity is less than 5
        stream: FirebaseFirestore.instance
            .collection('products')
            .where(
              'medicalId',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid,
            )
            .where('quantity', isLessThan: 5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Stock Levels Healthy",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              var doc = snapshot.data!.docs[i];
              var product = doc.data() as Map<String, dynamic>;
              int qty = product['quantity'] ?? 0;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade100),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                    ),
                  ),
                  title: Text(
                    product['name'] ?? "Unknown Product",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Category: ${product['category'] ?? 'General'}",
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$qty Left",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        "Restock soon",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
