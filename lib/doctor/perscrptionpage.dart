import 'package:flutter/material.dart';

class PrescriptionsPage extends StatelessWidget {
  const PrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prescriptions")),
      body: const Center(
        child: Text(
          "Here you can issue medicines",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
