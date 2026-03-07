// TODO Implement this library.
import 'package:flutter/material.dart';

class DonateOrganPage extends StatelessWidget {
  const DonateOrganPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Organ Donation"),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
            const Text(
              "Be a Hero. Save Lives ❤️",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Registering as an organ donor means you agree to donate your organs after death to help save or improve lives.",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            const Text(
              "Organs That Can Be Donated:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            _buildOrganItem("❤️ Heart"),
            _buildOrganItem("🫁 Lungs"),
            _buildOrganItem("🧠 Liver"),
            _buildOrganItem("👁️ Eyes"),
            _buildOrganItem("🩸 Kidneys"),

            const SizedBox(height: 30),

            const Text(
              "Why Donate?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text("• One donor can save up to 8 lives."),
            const Text("• Gives hope to families."),
            const Text("• Creates a lasting legacy."),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DonorRegistrationPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Register as Donor",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildOrganItem(String organ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(organ, style: const TextStyle(fontSize: 16)),
    );
  }
}

class DonorRegistrationPage extends StatelessWidget {
  const DonorRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donor Registration"),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              decoration: InputDecoration(
                labelText: "Age",
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
                  const SnackBar(content: Text("Registered Successfully ❤️")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
