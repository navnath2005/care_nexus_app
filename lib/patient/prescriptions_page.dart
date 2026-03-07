import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionsPage extends StatelessWidget {
  const PrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Prescriptions")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('medicalId', isEqualTo: user!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No prescriptions yet"));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data();

              String status = data['status'];
              Color statusColor;

              if (status == "Completed") {
                statusColor = Colors.green;
              } else if (status == "Processing") {
                statusColor = Colors.orange;
              } else {
                statusColor = Colors.blue;
              }
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(data['medicineName'] ?? 'Medicine'),
                  subtitle: Text(data['quantity'] ?? 'N/A'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
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
