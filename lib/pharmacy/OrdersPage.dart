import 'package:care_nexus/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_page.dart';

// --- NEW ORDER PAGE ---
class NewOrderPage extends StatefulWidget {
  const NewOrderPage({super.key});

  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _itemController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  void _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;

      try {
        await FirebaseFirestore.instance.collection('orders').add({
          'medicalId': user?.uid,
          'customerName': _customerController.text.trim(),
          'item': _itemController.text.trim(),
          'totalPrice': double.parse(_amountController.text.trim()),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Completed',
        });
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Order")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(labelText: "Customer Name"),
                validator: (val) => val!.isEmpty ? "Enter name" : null,
              ),
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(labelText: "Medicine/Item"),
                validator: (val) => val!.isEmpty ? "Enter item" : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: "Price Amount (\$)",
                ),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Enter price" : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Confirm Order",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MAIN DASHBOARD ---
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

  @override
  Widget build(BuildContext context) {
    if (user == null)
      return const Scaffold(body: Center(child: Text("No User Logged In")));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Scaffold(body: Center(child: Text("Error")));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

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
              MaterialPageRoute(builder: (_) => const NewOrderPage()),
            ),
            backgroundColor: Colors.blue.shade700,
            icon: const Icon(
              Icons.add_shopping_cart_rounded,
              color: Colors.white,
            ),
            label: const Text(
              "New Order",
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
            "Orders",
            "orders",
            Icons.shopping_cart_checkout,
            Colors.blue,
          ),
          _buildQueryStatCard(
            "Low Stock",
            "products",
            Icons.warning_amber_rounded,
            Colors.orange,
            isLow: true,
          ),
          _buildRevenueStatCard(),
        ],
      ),
    );
  }

  Widget _buildQueryStatCard(
    String label,
    String coll,
    IconData icon,
    Color color, {
    bool isLow = false,
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
        return _buildStatUI(label, count, icon, color);
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
            total += (doc.data() as Map<String, dynamic>)['totalPrice'] ?? 0.0;
          }
        }
        return _buildStatUI(
          "Revenue",
          "\$${total.toStringAsFixed(1)}",
          Icons.payments_outlined,
          Colors.green,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _stockRow("Tablets", 0.82, Colors.blue),
          const Divider(height: 30),
          _stockRow("Syrups", 0.15, Colors.orange),
          const Divider(height: 30),
          _stockRow("Vaccines", 0.55, Colors.green),
        ],
      ),
    );
  }

  Widget _stockRow(String title, double val, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              "${(val * 100).toInt()}% Remaining",
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: val,
            minHeight: 7,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreServicesGrid() {
    final services = [
      {'n': 'Inventory', 'i': Icons.inventory, 'c': Colors.indigo},
      {'n': 'Analytics', 'i': Icons.analytics, 'c': Colors.teal},
      {'n': 'Customers', 'i': Icons.people, 'c': Colors.purple},
      {'n': 'Suppliers', 'i': Icons.local_shipping, 'c': Colors.amber},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
      ),
      itemCount: services.length,
      itemBuilder: (context, i) => Column(
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
          _drawerItem(Icons.history_edu_rounded, "Order History", () {}),
          _drawerItem(
            Icons.logout_rounded,
            "Sign Out",
            logout,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 20),
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
