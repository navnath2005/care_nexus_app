import 'package:flutter/material.dart';

class MedicinesPage extends StatelessWidget {
  const MedicinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Medicines")),
      body: const Center(child: Text("Add or update medicines here")),
    );
  }
}
