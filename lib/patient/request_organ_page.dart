// TODO Implement this library.
import 'package:flutter/material.dart';

class RequestOrganPage extends StatelessWidget {
  const RequestOrganPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Organ Requests"),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Example Card (Later connect to Firebase)
          _buildRequestCard(
            organ: "Kidney",
            bloodGroup: "O+",
            patientName: "Rahul Patil",
            status: "Pending",
          ),

          const SizedBox(height: 10),

          _buildRequestCard(
            organ: "Liver",
            bloodGroup: "A+",
            patientName: "Anita Sharma",
            status: "Approved",
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewOrganRequestPage(),
            ),
          );
        },
        label: const Text("New Request"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  static Widget _buildRequestCard({
    required String organ,
    required String bloodGroup,
    required String patientName,
    required String status,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF1E3A8A),
          child: Icon(Icons.favorite, color: Colors.white),
        ),
        title: Text("$organ Required"),
        subtitle: Text("Patient: $patientName\nBlood Group: $bloodGroup"),
        trailing: Text(
          status,
          style: TextStyle(
            color: status == "Approved" ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class NewOrganRequestPage extends StatelessWidget {
  const NewOrganRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Organ Request"),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: "Patient Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                  labelText: "Required Organ",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                  labelText: "Blood Group",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Request Submitted Successfully"),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Submit Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
