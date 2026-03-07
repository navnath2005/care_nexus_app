import 'package:flutter/material.dart';

import 'doctor_details_page.dart';

class FamilyDoctorPage extends StatelessWidget {
  const FamilyDoctorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final doctors = [
      {
        "name": "Dr. Aditi Sharma",
        "specialization": "General Physician",
        "experience": "10 yrs",
      },
      {
        "name": "Dr. Rajesh Kumar",
        "specialization": "Pediatrician",
        "experience": "15 yrs",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Family Doctors"),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 15),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(doctor["name"]!),
              subtitle: Text(
                "${doctor["specialization"]} • ${doctor["experience"]}",
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.blue,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorDetailsPage(
                      doctorName: doctor["name"]!,
                      specialization: doctor["specialization"]!,
                      experience: doctor["experience"]!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
