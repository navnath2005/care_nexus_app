import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State {
  int _selectedIndex = 0;

  final List pages = [
    const AdminOverviewPage(),
    const UsersManagementPage(),
    const AnalyticsPage(),
    const SettingsPage(),
  ];

  final List<String> navLabels = ["Overview", "Users", "Analytics", "Settings"];

  final List<IconData> navIcons = [
    Icons.dashboard,
    Icons.people,
    Icons.analytics,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          "Care Nexus Admin",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 12),
                    Text("Profile"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text("Logout", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.grey.shade900,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Admin Panel",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.builder(
                    itemCount: navLabels.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade600
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Icon(
                            navIcons[index],
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade400,
                          ),
                          title: Text(
                            navLabels[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade400,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                          onTap: () => setState(() => _selectedIndex = index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }
}

// ============ OVERVIEW PAGE ============

class AdminOverviewPage extends StatelessWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome Back, Admin!",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Here's an overview of Care Nexus platform",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          // Stats Grid - Now fetching from Firebase
          GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _FirebaseStatCard(
                title: "Total Users",
                icon: Icons.people,
                color: Colors.blue,
                collectionName: "users",
              ),
              _FirebaseStatCard(
                title: "Active Sessions",
                icon: Icons.computer,
                color: Colors.green,
                collectionName: "users",
                whereField: "isActive",
                whereValue: true,
              ),
              _FirebaseStatCard(
                title: "Pending Requests",
                icon: Icons.hourglass_top,
                color: Colors.orange,
                collectionName: "requests",
                whereField: "status",
                whereValue: "pending",
              ),
              _FirebaseStatCard(
                title: "System Health",
                icon: Icons.favorite,
                color: Colors.red,
                isHealth: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Recent Activity - Fetching from Firebase
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Recent Activity",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("activity")
                        .orderBy("timestamp", descending: true)
                        .limit(3)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 32),
                              const SizedBox(height: 8),
                              Text("Error: ${snapshot.error}"),
                            ],
                          ),
                        );
                      }

                      final activities = snapshot.data?.docs ?? [];
                      if (activities.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "No recent activity. Try adding some data to the 'activity' collection.",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activities.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final activity =
                              activities[index].data() as Map<String, dynamic>;
                          return _ActivityItem(
                            title: activity["title"] ?? "Unknown activity",
                            subtitle: activity["description"] ?? "",
                            time: _formatTime(
                              activity["timestamp"] as Timestamp?,
                            ),
                            icon: _getActivityIcon(activity["type"] ?? ""),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "Recently";
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} minutes ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hours ago";
    } else {
      return "${difference.inDays} days ago";
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case "user_registration":
        return Icons.person_add;
      case "system_update":
        return Icons.update;
      case "emergency_service":
        return Icons.local_hospital;
      default:
        return Icons.info;
    }
  }
}

class _FirebaseStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? collectionName;
  final String? whereField;
  final dynamic whereValue;
  final bool isHealth;

  const _FirebaseStatCard({
    required this.title,
    required this.icon,
    required this.color,
    this.collectionName,
    this.whereField,
    this.whereValue,
    this.isHealth = false,
  });

  @override
  Widget build(BuildContext context) {
    // If it's health stat, just show static value
    if (isHealth) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "99.8%",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // Build query based on filters
    Query query = FirebaseFirestore.instance.collection(collectionName ?? "");

    if (whereField != null && whereValue != null) {
      query = query.where(whereField as Object, isEqualTo: whereValue);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        String value = "0";
        bool hasError = false;

        if (snapshot.hasError) {
          hasError = true;
          value = "Error";
        } else if (snapshot.hasData) {
          value = snapshot.data!.docs.length.toString();
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: hasError ? Colors.red : Colors.black,
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Check Firestore permissions & collection name",
                    style: TextStyle(fontSize: 10, color: Colors.red.shade700),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============ USERS MANAGEMENT PAGE ============

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State {
  late Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance.collection("users").snapshots();
  }

  void _editUserRole(String userId, String currentRole) {
    showDialog(
      context: context,
      builder: (context) {
        String role = currentRole;
        return AlertDialog(
          title: const Text("Edit Role"),
          content: DropdownButtonFormField<String>(
            value: role,
            items: const [
              DropdownMenuItem(value: "Admin", child: Text("Admin")),
              DropdownMenuItem(value: "Doctor", child: Text("Doctor")),
              DropdownMenuItem(value: "Patient", child: Text("Patient")),
            ],
            onChanged: (value) {
              if (value != null) {
                role = value;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(userId)
                      .update({"role": role});
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Role updated successfully"),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: Text("Are you sure you want to delete $userName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
                    .delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User deleted successfully")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addUser() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = "Patient";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New User"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Admin", child: Text("Admin")),
                  DropdownMenuItem(value: "Doctor", child: Text("Doctor")),
                  DropdownMenuItem(value: "Patient", child: Text("Patient")),
                ],
                onChanged: (value) {
                  selectedRole = value ?? "Patient";
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty || emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all fields")),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance.collection("users").add({
                  "name": nameController.text,
                  "email": emailController.text,
                  "role": selectedRole,
                  "createdAt": FieldValue.serverTimestamp(),
                  "isActive": true,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User added successfully")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "User Management",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add User"),
                onPressed: _addUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 200, child: _headerCell("Name")),
                      SizedBox(width: 200, child: _headerCell("Email")),
                      SizedBox(width: 120, child: _headerCell("Role")),
                      SizedBox(width: 150, child: _headerCell("Status")),
                      SizedBox(width: 120, child: _headerCell("Actions")),
                    ],
                  ),
                ),
                // Table Rows
                StreamBuilder<QuerySnapshot>(
                  stream: _usersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 32),
                            const SizedBox(height: 8),
                            Text("Error: ${snapshot.error}"),
                            const SizedBox(height: 8),
                            const Text(
                              "Make sure 'users' collection exists in Firestore",
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    final users = snapshot.data?.docs ?? [];
                    if (users.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "No users found. Click 'Add User' to create one.",
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userDoc = users[index];
                        final user = userDoc.data() as Map<String, dynamic>;
                        final userId = userDoc.id;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 200,
                                child: Text(user["name"] ?? "N/A"),
                              ),
                              SizedBox(
                                width: 200,
                                child: Text(user["email"] ?? "N/A"),
                              ),
                              SizedBox(
                                width: 120,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user["role"] ?? "User",
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "Active",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editUserRole(
                                        userId,
                                        user["role"] ?? "User",
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteUser(
                                        userId,
                                        user["name"] ?? "User",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }
}

// ============ ANALYTICS PAGE ============

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Analytics & Reports",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _FirebaseAnalyticsCard(
                title: "Total Users",
                icon: Icons.people,
                color: Colors.green,
                collectionName: "users",
              ),
              _FirebaseAnalyticsCard(
                title: "Active Sessions",
                icon: Icons.bar_chart,
                color: Colors.blue,
                collectionName: "users",
                whereField: "isActive",
                whereValue: true,
              ),
              _FirebaseAnalyticsCard(
                title: "Pending Requests",
                icon: Icons.speed,
                color: Colors.purple,
                collectionName: "requests",
                whereField: "status",
                whereValue: "pending",
              ),
              _FirebaseAnalyticsCard(
                title: "Completed Tasks",
                icon: Icons.check_circle,
                color: Colors.orange,
                collectionName: "tasks",
                whereField: "status",
                whereValue: "completed",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FirebaseAnalyticsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String collectionName;
  final String? whereField;
  final dynamic whereValue;

  const _FirebaseAnalyticsCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.collectionName,
    this.whereField,
    this.whereValue,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection(collectionName);

    if (whereField != null && whereValue != null) {
      query = query.where(whereField as Object, isEqualTo: whereValue);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        bool hasError = false;
        bool isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (snapshot.hasError) {
          hasError = true;
        } else if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (hasError)
                  Text(
                    "Error",
                    style: TextStyle(fontSize: 14, color: Colors.red.shade600),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    "$count records",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============ SETTINGS PAGE ============

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State createState() => _SettingsPageState();
}

class _SettingsPageState extends State {
  bool _notificationsEnabled = true;
  bool _maintenanceMode = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Settings",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "System Settings",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _SettingTile(
                    title: "Notifications",
                    subtitle: "Enable/disable system notifications",
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      setState(() => _notificationsEnabled = value);
                      await FirebaseFirestore.instance
                          .collection("settings")
                          .doc("system")
                          .set({
                            "notificationsEnabled": value,
                          }, SetOptions(merge: true));
                    },
                  ),
                  const Divider(),
                  _SettingTile(
                    title: "Maintenance Mode",
                    subtitle: "Temporarily disable access to the platform",
                    value: _maintenanceMode,
                    onChanged: (value) async {
                      setState(() => _maintenanceMode = value);
                      await FirebaseFirestore.instance
                          .collection("settings")
                          .doc("system")
                          .set({
                            "maintenanceMode": value,
                          }, SetOptions(merge: true));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Danger Zone",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showDangerDialog(
                          context,
                          "Reset Database",
                          "Are you sure you want to reset the database? This cannot be undone.",
                          () async {
                            // Reset database logic here
                            await FirebaseFirestore.instance
                                .collection("backup")
                                .add({
                                  "action": "database_reset",
                                  "timestamp": FieldValue.serverTimestamp(),
                                });
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("Reset Database"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showDangerDialog(
                          context,
                          "Clear Cache",
                          "Are you sure you want to clear the cache?",
                          () {
                            // Clear cache logic here
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("Clear Cache"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDangerDialog(
    BuildContext context,
    String title,
    String message,
    Function onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await onConfirm();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("$title completed")));
              }
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ============ CUSTOM WIDGETS ============

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
