import 'package:care_nexus/ambulance/BookingCompletionScreen.dart';
import 'package:care_nexus/ambulance/Navigation%20Screen.dart';
import 'package:care_nexus/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../auth/login_page.dart';

import 'booking_completion_screen.dart';

/// Professional ambulance dashboard with all features integrated
class AmbulanceDashboard extends StatefulWidget {
  const AmbulanceDashboard({super.key});

  @override
  State<AmbulanceDashboard> createState() => _AmbulanceDashboardState();
}

class _AmbulanceDashboardState extends State<AmbulanceDashboard>
    with WidgetsBindingObserver {
  late final User? _currentUser;
  late final FirebaseFirestore _firestore;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUser = FirebaseAuth.instance.currentUser;
    _firestore = FirebaseFirestore.instance;
    _setOnlineStatus(true);
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUser == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _setOnlineStatus(true);
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _setOnlineStatus(false);
    }
  }

  Future<void> _setOnlineStatus(bool status) async {
    if (_currentUser == null || _isDisposed) return;

    try {
      await _firestore.collection("users").doc(_currentUser!.uid).update({
        'isOnline': status,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  Future<void> _logout() async {
    if (_currentUser == null) return;

    try {
      await _firestore.collection("users").doc(_currentUser!.uid).update({
        'isOnline': false,
      });
      await FirebaseAuth.instance.signOut();

      if (!_isDisposed && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFEA580C);
      case 'URGENT':
        return const Color(0xFFF97316);
      case 'MODERATE':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Future<void> _acceptBooking(String bookingId) async {
    if (_currentUser == null || _isDisposed) return;

    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'accepted',
        'driverId': _currentUser!.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Emergency accepted successfully'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error accepting booking: $e');
    }
  }

  Future<void> _startNavigation(
    String bookingId,
    String destination,
    double destLat,
    double destLng,
    String patientName,
    String emergencyType,
    String priority,
  ) async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NavigationScreen(
            bookingId: bookingId,
            destination: destination,
            destinationLat: destLat,
            destinationLng: destLng,
            patientName: patientName,
            emergencyType: emergencyType,
            priority: priority,
          ),
        ),
      );
    }
  }

  void _completeBooking(
    String bookingId,
    String patientName,
    String emergencyType,
    DateTime acceptedAt,
  ) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingCompletionScreen(
            bookingId: bookingId,
            patientName: patientName,
            emergencyType: emergencyType,
            acceptedAt: acceptedAt,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection("users").doc(_currentUser!.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FD),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userSnapshot.data!.exists) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FD),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('User profile not found'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text('Return to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final bool isOnline = userData['isOnline'] ?? false;
        final String name = userData['name'] ?? "Responder";

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: _buildAppBar(),
          body: RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(name: name),
                  const SizedBox(height: 20),
                  _StatusToggle(
                    isOnline: isOnline,
                    onChanged: _setOnlineStatus,
                  ),
                  const SizedBox(height: 24),
                  _DynamicStatsRow(
                    userId: _currentUser!.uid,
                    firestore: _firestore,
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader("Quick Actions"),
                  const SizedBox(height: 12),
                  _ActionGrid(),
                  const SizedBox(height: 28),
                  _buildSectionHeader("Active Emergencies"),
                  const SizedBox(height: 12),
                  _ActiveEmergenciesStream(
                    userId: _currentUser!.uid,
                    firestore: _firestore,
                    getPriorityColor: _getPriorityColor,
                    onNavigate: _startNavigation,
                    onComplete: _completeBooking,
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader("Incoming Emergencies"),
                  const SizedBox(height: 12),
                  _EmergencyListStream(
                    firestore: _firestore,
                    onAcceptBooking: _acceptBooking,
                    getPriorityColor: _getPriorityColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        "CareNexus Response",
        style: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          fontSize: 18,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1F2937),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      actions: [
        Tooltip(
          message: 'Logout',
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            onPressed: _logout,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
      ),
    );
  }
}

// ============================================================================
// ACTIVE EMERGENCIES STREAM (NEW)
// ============================================================================

class _ActiveEmergenciesStream extends StatelessWidget {
  final String userId;
  final FirebaseFirestore firestore;
  final Color Function(String?) getPriorityColor;
  final Function(String, String, double, double, String, String, String)
  onNavigate;
  final Function(String, String, String, DateTime) onComplete;

  const _ActiveEmergenciesStream({
    required this.userId,
    required this.firestore,
    required this.getPriorityColor,
    required this.onNavigate,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('bookings')
          .where('driverId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final location = data['pickupLocation'] as GeoPoint?;

            return _ActiveEmergencyCard(
              bookingId: doc.id,
              patientName: data['patientName'] ?? 'Unknown',
              location: data['pickupAddress'] ?? 'No address',
              emergencyType: data['emergencyType'] ?? 'Emergency',
              priority: data['priority'] ?? 'NORMAL',
              priorityColor: getPriorityColor(data['priority']),
              destinationLat: location?.latitude ?? 0,
              destinationLng: location?.longitude ?? 0,
              acceptedAt:
                  (data['acceptedAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              onNavigate: () => onNavigate(
                doc.id,
                data['pickupAddress'] ?? 'Destination',
                location?.latitude ?? 0,
                location?.longitude ?? 0,
                data['patientName'] ?? 'Patient',
                data['emergencyType'] ?? 'Emergency',
                data['priority'] ?? 'NORMAL',
              ),
              onComplete: () => onComplete(
                doc.id,
                data['patientName'] ?? 'Unknown',
                data['emergencyType'] ?? 'Emergency',
                (data['acceptedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              ),
            );
          },
        );
      },
    );
  }
}

class _ActiveEmergencyCard extends StatelessWidget {
  final String bookingId;
  final String patientName;
  final String location;
  final String emergencyType;
  final String priority;
  final Color priorityColor;
  final double destinationLat;
  final double destinationLng;
  final DateTime acceptedAt;
  final VoidCallback onNavigate;
  final VoidCallback onComplete;

  const _ActiveEmergencyCard({
    required this.bookingId,
    required this.patientName,
    required this.location,
    required this.emergencyType,
    required this.priority,
    required this.priorityColor,
    required this.destinationLat,
    required this.destinationLng,
    required this.acceptedAt,
    required this.onNavigate,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final duration = DateTime.now().difference(acceptedAt).inMinutes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: priorityColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emergencyType,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${duration}m in',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      color: const Color(0xFF4B5563),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Navigate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: priorityColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// REUSABLE WIDGETS
// ============================================================================

class _ProfileHeader extends StatelessWidget {
  final String name;

  const _ProfileHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.8),
                const Color(0xFF1D4ED8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back,",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusToggle extends StatefulWidget {
  final bool isOnline;
  final Function(bool) onChanged;

  const _StatusToggle({required this.isOnline, required this.onChanged});

  @override
  State<_StatusToggle> createState() => _StatusToggleState();
}

class _StatusToggleState extends State<_StatusToggle> {
  late bool _localStatus;

  @override
  void initState() {
    super.initState();
    _localStatus = widget.isOnline;
  }

  @override
  void didUpdateWidget(_StatusToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      _localStatus = widget.isOnline;
    }
  }

  void _toggleStatus(bool value) {
    setState(() => _localStatus = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _localStatus ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _localStatus
              ? const Color(0x3310B981)
              : const Color(0x33D1D5DB),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _localStatus
                        ? const Color(0xFF10B981)
                        : const Color(0xFF9CA3AF),
                    boxShadow: _localStatus
                        ? [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localStatus ? "YOU ARE ONLINE" : "YOU ARE OFFLINE",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _localStatus
                            ? const Color(0xFF059669)
                            : const Color(0xFF6B7280),
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _localStatus ? "Ready to respond" : "Not available",
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _localStatus,
            onChanged: _toggleStatus,
            activeColor: const Color(0xFF10B981),
            inactiveThumbColor: const Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}

class _DynamicStatsRow extends StatelessWidget {
  final String userId;
  final FirebaseFirestore firestore;

  const _DynamicStatsRow({required this.userId, required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('bookings')
          .where('driverId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        int active = 0;
        int completed = 0;

        if (snapshot.hasData) {
          active = snapshot.data!.docs
              .where((d) => d['status'] == 'accepted')
              .length;
          completed = snapshot.data!.docs
              .where((d) => d['status'] == 'completed')
              .length;
        }

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                label: "Active",
                value: active.toString(),
                color: const Color(0xFFF97316),
                icon: Icons.local_activity_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: "Completed",
                value: completed.toString(),
                color: const Color(0xFF10B981),
                icon: Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: "Rating",
                value: "4.9",
                color: const Color(0xFF3B82F6),
                icon: Icons.star_rounded,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.map_rounded,
        title: "Maps",
        color: const Color(0xFF4F46E5),
      ),
      _ActionItem(
        icon: Icons.history_rounded,
        title: "History",
        color: const Color(0xFF06B6D4),
      ),
      _ActionItem(
        icon: Icons.medical_services_rounded,
        title: "Equipment",
        color: const Color(0xFF14B8A6),
      ),
      _ActionItem(
        icon: Icons.settings_rounded,
        title: "Settings",
        color: const Color(0xFF3B82F6),
      ),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      itemBuilder: (context, index) => _ActionCard(item: actions[index]),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final Color color;

  _ActionItem({required this.icon, required this.title, required this.color});
}

class _ActionCard extends StatefulWidget {
  final _ActionItem item;

  const _ActionCard({required this.item});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? widget.item.color.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.item.color.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.item.icon,
                  color: widget.item.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyListStream extends StatelessWidget {
  final FirebaseFirestore firestore;
  final Function(String) onAcceptBooking;
  final Color Function(String?) getPriorityColor;

  const _EmergencyListStream({
    required this.firestore,
    required this.onAcceptBooking,
    required this.getPriorityColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('bookings')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 40),
                const SizedBox(height: 12),
                const Text(
                  "Failed to load emergencies",
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "No emergency requests",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You're all caught up!",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _EmergencyCard(
              bookingId: doc.id,
              patientName: data['patientName'] ?? 'Unknown',
              location: data['pickupAddress'] ?? 'No address available',
              emergencyType: data['emergencyType'] ?? 'Medical Emergency',
              priority: data['priority'] ?? 'NORMAL',
              priorityColor: getPriorityColor(data['priority']),
              onAccept: onAcceptBooking,
            );
          },
        );
      },
    );
  }
}

class _EmergencyCard extends StatefulWidget {
  final String bookingId;
  final String patientName;
  final String location;
  final String emergencyType;
  final String priority;
  final Color priorityColor;
  final Function(String) onAccept;

  const _EmergencyCard({
    required this.bookingId,
    required this.patientName,
    required this.location,
    required this.emergencyType,
    required this.priority,
    required this.priorityColor,
    required this.onAccept,
  });

  @override
  State<_EmergencyCard> createState() => _EmergencyCardState();
}

class _EmergencyCardState extends State<_EmergencyCard> {
  bool _isAccepting = false;

  Future<void> _handleAccept() async {
    setState(() => _isAccepting = true);
    await widget.onAccept(widget.bookingId);
    if (mounted) {
      setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: widget.priorityColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.emergencyType,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.priority,
                    style: TextStyle(
                      color: widget.priorityColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.location,
                    style: TextStyle(
                      color: const Color(0xFF4B5563),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAccepting ? null : _handleAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.priorityColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isAccepting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        "RESPOND NOW",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
