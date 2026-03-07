import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SyrupsPage extends StatelessWidget {
  const SyrupsPage({super.key});

  void _showProductSheet(BuildContext context, {DocumentSnapshot? doc}) {
    final nameController = TextEditingController(
      text: doc != null ? doc['name'] : "",
    );
    final priceController = TextEditingController(
      text: doc != null ? doc['price'].toString() : "",
    );
    final qtyController = TextEditingController(
      text: doc != null ? doc['quantity'].toString() : "",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  doc == null ? "Add Syrup" : "Edit Syrup",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (doc != null)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    onPressed: () async {
                      // DELETE CONFIRMATION DIALOG
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete Syrup"),
                          content: const Text(
                            "Are you sure you want to delete this syrup?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('products')
                            .doc(doc.id)
                            .delete();
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
              ],
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: "Quantity"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                ),
                onPressed: () async {
                  // VALIDATION
                  if (nameController.text.trim().isEmpty ||
                      priceController.text.trim().isEmpty ||
                      qtyController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("All fields are required")),
                    );
                    return;
                  }

                  final data = {
                    'medicalId': FirebaseAuth.instance.currentUser?.uid,
                    'name': nameController.text.trim(),
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'quantity': int.tryParse(qtyController.text) ?? 0,
                    'category': 'Syrups',
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (doc == null) {
                    await FirebaseFirestore.instance
                        .collection('products')
                        .add(data);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('products')
                        .doc(doc.id)
                        .update(data);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(
                  doc == null ? "Add Syrup" : "Update Details",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> sellProduct(String docId, int quantityToSell) async {
    final docRef = FirebaseFirestore.instance.collection('products').doc(docId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception("Product does not exist!");

        int currentQty = snapshot['quantity'];

        if (currentQty >= quantityToSell) {
          transaction.update(docRef, {
            'quantity': currentQty - quantityToSell,
            'lastSaleAt': FieldValue.serverTimestamp(),
          });
        } else {
          throw Exception("Insufficient stock!");
        }
      });
    } catch (e) {
      print("Sale failed: ₹ e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductSheet(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where(
              'medicalId',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid,
            )
            .where('category', isEqualTo: 'Syrups')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text("No Syrups found"));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              var product = snapshot.data!.docs[i];
              return Card(
                child: ListTile(
                  title: Text(
                    product['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Price: \₹ ${product['price']}"),
                  trailing: Text(
                    "${product['quantity']}",
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () => _showProductSheet(context, doc: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
