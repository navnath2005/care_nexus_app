import 'package:care_nexus/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_page.dart';

// Import the pages from your file structure
import 'OrdersTodayPage.dart';
import 'LowStockPage.dart';
import 'InventoryPage.dart';
import 'ReportsPage.dart';
import 'MedicinesPage.dart';
import 'OrdersPage.dart';

class MedicalDashboard extends StatefulWidget {
  const MedicalDashboard({super.key});

  @override
  State<MedicalDashboard> createState() => _MedicalDashboardState();
}

class _MedicalDashboardState extends State<MedicalDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // UPDATED: Function to handle order status changes
  Future<void> _changeStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': newStatus},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order marked as $newStatus"),
            backgroundColor: newStatus == "Accepted"
                ? Colors.green
                : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.black),
        );
      }
    }
  }

  

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("No User Logged In")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Scaffold(body: Center(child: Text("Error")));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final String userName = userData['name'] ?? 'Pharmacist';
        final String userEmail = userData['email'] ?? 'pharmacy@care.com';

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          drawer: _buildSidebar(userName, userEmail),
          appBar: _buildAppBar(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersPage()),
            ),
            backgroundColor: Colors.blue.shade700,
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
            label: const Text(
              "View Orders",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(userName),
                const SizedBox(height: 25),
                const _SectionTitle(title: "Overview Today"),
                const SizedBox(height: 15),
                _buildHorizontalStats(),
                const SizedBox(height: 30),

                // NEW: Real-time action area for the buttons you added
                const _SectionTitle(title: "Pending Orders"),
                const SizedBox(height: 15),
                _buildActionableOrdersList(),

                const SizedBox(height: 30),
                const _SectionTitle(title: "Inventory Status"),
                const SizedBox(height: 15),
                _buildStockTracker(),
                const SizedBox(height: 30),
                const _SectionTitle(title: "More Services"),
                const SizedBox(height: 15),
                _buildMoreServicesGrid(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UI WIDGETS ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.notes_rounded, color: Colors.black, size: 30),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.black,
          ),
          onPressed: () {},
        ),
        const Padding(
          padding: EdgeInsets.only(right: 15),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CareNexus Medical",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            "Welcome, $name! 💊",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStats() {
    return SizedBox(
      height: 115,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildQueryStatCard(
            "Orders Today",
            "orders",
            Icons.shopping_cart_checkout,
            Colors.blue,
            targetPage: const OrdersPage(),
          ),
          _buildQueryStatCard(
            "Low Stock",
            "products",
            Icons.warning_amber_rounded,
            Colors.orange,
            isLow: true,
            targetPage: const LowStockPage(),
          ),
          _buildRevenueStatCard(),
        ],
      ),
    );
  }

  // UPDATED: Actionable list for the pharmacist to Accept/Reject
  Widget _buildActionableOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('medicalId', isEqualTo: user?.uid)
          .where('status', isEqualTo: 'Pending')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Text(
            "No new orders to review",
            style: TextStyle(color: Colors.grey),
          );

        return Column(
          children: docs.map((doc) {
            final order = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: Text(
                  order['patientName'] ?? "Guest",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Amount: ₹${order['totalAmount']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      onPressed: () => _changeStatus(doc.id, "Accepted"),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      onPressed: () => _changeStatus(doc.id, "Rejected"),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Stat Card Builders
  Widget _buildQueryStatCard(
    String label,
    String coll,
    IconData icon,
    Color color, {
    bool isLow = false,
    required Widget targetPage,
  }) {
    Query query = FirebaseFirestore.instance
        .collection(coll)
        .where('medicalId', isEqualTo: user?.uid);
    if (isLow) query = query.where('quantity', isLessThan: 10);
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        String count = snapshot.hasData
            ? snapshot.data!.docs.length.toString()
            : "...";
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => targetPage),
          ),
          child: _buildStatUI(label, count, icon, color),
        );
      },
    );
  }

  Widget _buildRevenueStatCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('medicalId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        double total = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            total += (doc.data() as Map<String, dynamic>)['totalAmount'] ?? 0.0;
          }
        }
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportsPage()),
          ),
          child: _buildStatUI(
            "Revenue",
            "₹${total.toStringAsFixed(1)}",
            Icons.payments_outlined,
            Colors.green,
          ),
        );
      },
    );
  }

  Widget _buildStatUI(String label, String value, IconData icon, Color color) {
    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockTracker() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('medicalId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: LinearProgressIndicator());
        int tabletCount = 0;
        int syrupCount = 0;
        int vaccineCount = 0;
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          int qty = data['quantity'] ?? 0;
          String cat = data['category'] ?? "";
          if (cat == 'Tablets')
            tabletCount += qty;
          else if (cat == 'Syrups')
            syrupCount += qty;
          else if (cat == 'Vaccines')
            vaccineCount += qty;
        }
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              _stockRow(
                "Tablets",
                (tabletCount / 1000).clamp(0.0, 1.0),
                Colors.blue,
                tabletCount,
              ),
              const Divider(height: 30),
              _stockRow(
                "Syrups",
                (syrupCount / 1000).clamp(0.0, 1.0),
                Colors.orange,
                syrupCount,
              ),
              const Divider(height: 30),
              _stockRow(
                "Vaccines",
                (vaccineCount / 1000).clamp(0.0, 1.0),
                Colors.green,
                vaccineCount,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stockRow(String title, double progress, Color color, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "$count Units",
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }

  Widget _buildMoreServicesGrid() {
    final services = [
      {
        'n': 'Inventory',
        'i': Icons.inventory,
        'c': Colors.indigo,
        'p': const InventoryPage(),
      },
      {
        'n': 'Reports',
        'i': Icons.analytics,
        'c': Colors.teal,
        'p': const ReportsPage(),
      },
      {
        'n': 'Medicines',
        'i': Icons.medical_services,
        'c': Colors.purple,
        'p': const MedicinesPage(),
      },
      {
        'n': 'All Orders',
        'i': Icons.history,
        'c': Colors.amber,
        'p': const OrdersPage(),
      },
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
      ),
      itemCount: services.length,
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => services[i]['p'] as Widget),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: (services[i]['c'] as Color).withOpacity(0.1),
              child: Icon(
                services[i]['i'] as IconData,
                color: services[i]['c'] as Color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              services[i]['n'] as String,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(String name, String email) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade600],
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.local_pharmacy, color: Colors.blue, size: 35),
            ),
            accountName: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            accountEmail: Text(email),
          ),
          _drawerItem(
            Icons.dashboard_rounded,
            "Dashboard",
            () => Navigator.pop(context),
          ),
          _drawerItem(Icons.history_edu_rounded, "Order History", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersPage()),
            );
          }),
          _drawerItem(
            Icons.logout_rounded,
            "Sign Out",
            logout,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.blueGrey),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }
}
