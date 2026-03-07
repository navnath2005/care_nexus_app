import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'patient/patient_dashboard.dart';
import 'doctor/doctor_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'ambulance/ambulance_dashboard.dart';
import 'pharmacy/pharmacy_dashboard.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Something went wrong 🚨")),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("User record not found ⚠️")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = data["role"];

        switch (role) {
          case "Admin":
            return const AdminDashboard();
          case "Doctor":
            return const ProfessionalDoctorDashboard();
          case "Patient":
            return const PatientDashboard();
          case "Ambulance":
            return const AmbulanceDashboard();
          case "Medical":
            return const MedicalDashboard(); // 👈 fixed
          default:
            return const Scaffold(body: Center(child: Text("Unknown role 😕")));
        }
      },
    );
  }
}
