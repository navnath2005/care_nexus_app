import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MedicalStorePage extends StatefulWidget {
  const MedicalStorePage({super.key});

  @override
  State<MedicalStorePage> createState() => _MedicalStorePageState();
}

class _MedicalStorePageState extends State<MedicalStorePage> {
  final List<Map<String, dynamic>> _cart = [];
  String _searchQuery = ""; // Added for search functionality

  IconData _getIcon(String? iconType) {
    switch (iconType) {
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'medical_services':
        return Icons.medical_services;
      case 'vaccines':
        return Icons.vaccines;
      default:
        return Icons.medication;
    }
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to place an order")),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Extract pharmacyId from first item (fixed field name)
      final String pharmacyId = _cart.first['pharmacyId'] as String? ?? '';
      if (pharmacyId.isEmpty) {
        throw Exception('Invalid pharmacy information');
      }

      // Calculate total with type safety
      double total = _cart.fold(0.0, (sum, item) {
        final price = item['price'];
        if (price is num) {
          return sum + price.toDouble();
        }
        return sum;
      });

      // Prepare medicines array
      final List<Map<String, dynamic>> medicines = _cart.map((item) {
        return {
          'name': item['name'] ?? 'Unknown',
          'price': item['price'] is num ? item['price'].toDouble() : 0.0,
          'quantity': item['quantity'] ?? 1,
          'description': item['desc'] ?? '',
        };
      }).toList();

      // Create order with correct field names matching Firestore rules
      await FirebaseFirestore.instance.collection('orders').add({
        'patientId': user.uid,
        'patientName': user.displayName ?? "Customer",
        'pharmacyId': pharmacyId,
        'medicines': medicines,
        'deliveryAddress': '', // TODO: Get from user profile
        'totalAmount': total,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _cart.clear());
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) Navigator.pop(context); // Close cart sheet

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order Placed Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      _cart.add(item);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${item['name'] ?? 'Item'} added to cart!"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E3A8A),
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Calculate total inside builder so it updates when items are removed
            double total = _cart.fold(0.0, (sum, item) {
              final price = item['price'];
              return sum + (price is num ? price.toDouble() : 0.0);
            });

            return Container(
              padding: const EdgeInsets.all(20.0),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Your Cart (${_cart.length} items)",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  if (_cart.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Text("Your cart is empty"),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final item = _cart[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.medication,
                              color: Color(0xFF1E3A8A),
                            ),
                            title: Text(item['name'] ?? "Medicine"),
                            subtitle: Text("₹${item['price']}"),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                // Update both the Modal and the background Page
                                setModalState(() => _cart.removeAt(index));
                                setState(() {});
                                if (_cart.isEmpty && mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Amount:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "₹${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _cart.isEmpty ? null : () => _placeOrder(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Place Order",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Medical Store"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              label: Text(_cart.length.toString()),
              isLabelVisible: _cart.isNotEmpty,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: _showCartSheet,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Logic to filter products based on search
                final allDocs = snapshot.data?.docs ?? [];
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data == null) return false;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No products found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final item =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    return _buildMedicineCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Search medicines...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getIcon(item['icon_type'] as String?),
            color: const Color(0xFF1E3A8A),
          ),
        ),
        title: Text(
          item['name'] ?? 'Item',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(item['desc'] ?? ''),
        trailing: InkWell(
          onTap: () => _addToCart(item),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "₹${item['price'] ?? 0}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Add +",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
