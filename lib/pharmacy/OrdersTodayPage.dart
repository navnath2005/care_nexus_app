import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Orders"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('medicalId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var doc = orders[index];
              var order = doc.data() as Map<String, dynamic>;
              List items = order['items'] ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order['patientName'] ?? "Customer",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          _buildStatusChip(order['status'] ?? 'Pending'),
                        ],
                      ),
                      const Divider(),
                      // Display items in the order
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text("• ${item['name']} (₹${item['price']})"),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total: ₹${order['totalAmount']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          if (order['status'] == 'Pending')
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      _updateStatus(doc.id, "Rejected"),
                                  child: const Text(
                                    "Reject",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      _updateStatus(doc.id, "Accepted"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text(
                                    "Accept",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                        ],
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

  // Helper to change order status in Firestore
  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': status,
    });
  }

  // UI helper for status badges
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Accepted':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
