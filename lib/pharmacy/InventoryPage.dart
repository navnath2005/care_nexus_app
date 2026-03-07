import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'TabletsPage.dart';
import 'SyrupsPage.dart';
import 'VaccinesPage.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // We define the theme colors for each category here
  final List<Color> _tabColors = [
    Colors.blue.shade700, // Tablets
    Colors.orange.shade700, // Syrups
    Colors.green.shade700, // Vaccines
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // This updates the AppBar color/theme when you swipe between tabs
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 2,
        // The title color now shifts based on the active Firebase category
        title: Text(
          "Inventory Management",
          style: TextStyle(
            color: _tabColors[_tabController.index],
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _tabColors[_tabController.index],
          labelColor: _tabColors[_tabController.index],
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.medication), text: "Tablets"),
            Tab(icon: Icon(Icons.water_drop), text: "Syrups"),
            Tab(icon: Icon(Icons.vaccines), text: "Vaccines"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [TabletsPage(), SyrupsPage(), VaccinesPage()],
      ),
    );
  }
}

class InventoryCategoryPage extends StatelessWidget {
  final String category;

  const InventoryCategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('medicalId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No $category available"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, i) {
            final doc = snapshot.data!.docs[i];
            return ListTile(
              title: Text(doc['name']),
              subtitle: Text("₹${doc['price']}"),
              trailing: Text("${doc['quantity']}"),
            );
          },
        );
      },
    );
  }
}
