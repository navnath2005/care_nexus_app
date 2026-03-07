import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final nameCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();
  DateTime? date;
  TimeOfDay? time;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> book() async {
    if (nameCtrl.text.isEmpty ||
        reasonCtrl.text.isEmpty ||
        date == null ||
        time == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      await firestore.collection("appointments").add({
        "name": nameCtrl.text,
        "reason": reasonCtrl.text,
        "date": "${date!.day}/${date!.month}/${date!.year}",
        "time": time!.format(context),
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return; // Best practice: check if widget is still active

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment Booked Successfully!")),
      );

      nameCtrl.clear();
      reasonCtrl.clear();
      setState(() {
        date = null;
        time = null;
      });
    } catch (e) {
      debugPrint("Firestore Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ---- Booking Form ----
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: "Reason"),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );
                      setState(() {});
                    },
                    child: Text(
                      date == null
                          ? "Pick Date"
                          : "${date!.day}/${date!.month}/${date!.year}",
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      setState(() {});
                    },
                    child: Text(
                      time == null ? "Pick Time" : time!.format(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: book,
                  child: const Text("Book Appointment"),
                ),
              ),

              const SizedBox(height: 30),
              const Divider(),
              const Text(
                "My Appointments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // ---- Appointment Status List ----
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("appointments")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text("No appointments yet");
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final status = data["status"] ?? "pending";

                      return Card(
                        child: ListTile(
                          title: Text(data["reason"] ?? ""),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Date: ${data["date"]}"),
                              Text("Time: ${data["time"]}"),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              status.toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: status == "accepted"
                                ? Colors.green
                                : status == "rejected"
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
