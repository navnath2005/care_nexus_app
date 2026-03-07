import 'package:flutter/material.dart';

class DoctorDetailsPage extends StatelessWidget {
  final String doctorName;
  final String specialization;
  final String experience;

  const DoctorDetailsPage({
    super.key,
    required this.doctorName,
    required this.specialization,
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(doctorName),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              doctorName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(specialization, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              "Experience: $experience",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: () {
                // Future: Navigate to chat page
              },
              icon: const Icon(Icons.chat),
              label: const Text("Start Consultation"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
