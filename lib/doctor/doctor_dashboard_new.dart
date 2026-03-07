// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class DoctorDashboardNew extends StatelessWidget {
//   const DoctorDashboardNew({super.key});

//   Future<void> updateStatus(String docId, String status) async {
//     await FirebaseFirestore.instance
//         .collection("appointments")
//         .doc(docId)
//         .update({"status": status});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Doctor Dashboard"),
//         centerTitle: true,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream:
//             FirebaseFirestore.instance.collection("appointments").snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return const Center(child: Text("Error loading data"));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text("No Appointments Found"));
//           }

//           final docs = snapshot.data!.docs;

//           return ListView.builder(
//             padding: const EdgeInsets.all(10),
//             itemCount: docs.length,
//             itemBuilder: (context, index) {
//               final doc = docs[index];
//               final data = doc.data() as Map<String, dynamic>;

//               final name = data["name"] ?? "Unknown";
//               final reason = data["reason"] ?? "-";
//               final date = data["date"] ?? "-";
//               final time = data["time"] ?? "-";
//               final status = data["status"] ?? "pending";

//               return Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 margin: const EdgeInsets.symmetric(vertical: 8),
//                 child: Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Column(
//                     children: [
//                       ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: Colors.blue.shade100,
//                           child: Text("${index + 1}"),
//                         ),
//                         title: Text(
//                           name,
//                           style: const TextStyle(
//                               fontWeight: FontWeight.bold, fontSize: 16),
//                         ),
//                         subtitle: Padding(
//                           padding: const EdgeInsets.only(top: 6),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text("Reason: $reason"),
//                               Text("Date: $date"),
//                               Text("Time: $time"),
//                               Text("Status: $status"),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 8),

//                       // Buttons if pending
//                       if (status == "pending")
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.green),
//                               onPressed: () => updateStatus(doc.id, "accepted"),
//                               child: const Text("Accept"),
//                             ),
//                             const SizedBox(width: 10),
//                             ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.red),
//                               onPressed: () => updateStatus(doc.id, "rejected"),
//                               child: const Text("Reject"),
//                             ),
//                           ],
//                         )
//                       else
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: Chip(
//                             label: Text(
//                               status.toUpperCase(),
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                             backgroundColor: status == "accepted"
//                                 ? Colors.green
//                                 : Colors.red,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
