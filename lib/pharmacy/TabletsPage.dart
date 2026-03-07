import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TabletsPage extends StatelessWidget {
  const TabletsPage({super.key});

  void _showProductSheet(BuildContext context, {DocumentSnapshot? doc}) {
    // Safely cast data to a Map to avoid "field does not exist" errors
    final data = doc != null ? doc.data() as Map<String, dynamic> : {};

    final nameController = TextEditingController(text: data['name'] ?? "");
    final scientificNameController = TextEditingController(
      text: data['scientificName'] ?? "",
    );
    final dosageController = TextEditingController(text: data['dosage'] ?? "");
    final priceController = TextEditingController(
      text: data['price']?.toString() ?? "",
    );
    final qtyController = TextEditingController(
      text: data['quantity']?.toString() ?? "",
    );
    final expiryController = TextEditingController(
      text: data['expiryDate'] ?? "",
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    doc == null ? "Add Tablet" : "Edit Details",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (doc != null)
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _confirmDelete(context, doc),
                    ),
                ],
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Brand Name"),
              ),
              TextField(
                controller: scientificNameController,
                decoration: const InputDecoration(labelText: "Scientific Name"),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: "Dosage (mg)",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      decoration: const InputDecoration(
                        labelText: "Expiry (MM/YY)",
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: "Price"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      decoration: const InputDecoration(labelText: "Stock Qty"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (doc != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showSellDialog(context, doc),
                        child: const Text("Sell Item"),
                      ),
                    ),
                  if (doc != null) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                      ),
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            priceController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Name and Price are required"),
                            ),
                          );
                          return;
                        }

                        final newData = {
                          'medicalId': FirebaseAuth.instance.currentUser?.uid,
                          'name': nameController.text.trim(),
                          'scientificName': scientificNameController.text
                              .trim(),
                          'dosage': dosageController.text.trim(),
                          'expiryDate': expiryController.text.trim(),
                          'price': double.tryParse(priceController.text) ?? 0.0,
                          'quantity': int.tryParse(qtyController.text) ?? 0,
                          'category': 'Tablets',
                          'updatedAt': FieldValue.serverTimestamp(),
                        };

                        if (doc == null) {
                          await FirebaseFirestore.instance
                              .collection('products')
                              .add(newData);
                        } else {
                          await FirebaseFirestore.instance
                              .collection('products')
                              .doc(doc.id)
                              .update(newData);
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(
                        doc == null ? "Save" : "Update",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSellDialog(BuildContext context, DocumentSnapshot doc) {
    final sellQtyController = TextEditingController(text: "1");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Sell ${doc['name']}"),
        content: TextField(
          controller: sellQtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Quantity to sell"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              sellProduct(doc.id, int.tryParse(sellQtyController.text) ?? 0);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Confirm Sale"),
          ),
        ],
      ),
    );
  }

  Future<void> sellProduct(String docId, int quantityToSell) async {
    if (quantityToSell <= 0) return;
    final docRef = FirebaseFirestore.instance.collection('products').doc(docId);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;
        int currentQty = snapshot['quantity'] ?? 0;
        if (currentQty >= quantityToSell) {
          transaction.update(docRef, {
            'quantity': currentQty - quantityToSell,
            'lastSaleAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint("Sale failed: $e");
    }
  }

  void _confirmDelete(BuildContext context, DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text(
          "Are you sure you want to remove this tablet from inventory?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductSheet(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where(
              'medicalId',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid,
            )
            .where('category', isEqualTo: 'Tablets')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text("No Tablets found"));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              var doc = snapshot.data!.docs[i];
              var product = doc.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text(
                    "${product['name'] ?? 'Unnamed'} ${product['dosage'] ?? ''}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Exp: ${product['expiryDate'] ?? 'N/A'} • Price: \$${product['price'] ?? 0}",
                  ),
                  trailing: Text(
                    "${product['quantity'] ?? 0}",
                    style: TextStyle(
                      color: (product['quantity'] ?? 0) < 5
                          ? Colors.red
                          : Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () => _showProductSheet(context, doc: doc),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
