import 'package:care_nexus/chats/ChatListPage.dart';
import 'package:care_nexus/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// Project Imports
import 'package:care_nexus/profile/profile_page.dart';
import 'package:care_nexus/services/permission_service.dart';
import 'package:care_nexus/widgets/sos_button.dart';

// Pages
import '../auth/login_page.dart';
import '../chats/chatpage.dart';
import 'appointments_page.dart';
import 'health_records_page.dart';
import 'medical_store_page.dart';
import 'hospital_details_page.dart';
import 'familydoctorpage.dart';
import 'donate_organ_page.dart';
import 'request_organ_page.dart';
import 'hospital_schemes_page.dart';

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
class _AppColors {
  static const primary = Color(0xFF0A2463);
  static const primaryLight = Color(0xFF1E4DB7);
  static const accent = Color(0xFF3BCEAC);
  static const danger = Color(0xFFE63946);
  static const warning = Color(0xFFF4A261);
  static const success = Color(0xFF2DC653);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F7FC);
  static const textPrimary = Color(0xFF0D1B2A);
  static const textSecondary = Color(0xFF64748B);
  static const divider = Color(0xFFE2E8F0);
}

class _AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: _AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static const heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: _AppColors.textPrimary,
    letterSpacing: -0.3,
  );
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: _AppColors.textSecondary,
    letterSpacing: 0.5,
  );
  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _AppColors.textSecondary,
    height: 1.6,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _AppColors.textSecondary,
  );
}

// ─────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────
class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;
  late Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .snapshots();
    PermissionService.requestAllPermissions();
  }

  // ── Navigation Helpers ──────────────────────
  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ── Maps ────────────────────────────────────
  Future<void> _openNearby(String place) async {
    final query = Uri.encodeComponent('$place near me');
    final googleMaps = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    final appleMaps = Uri.parse('http://maps.apple.com/?q=$query');

    try {
      if (await canLaunchUrl(googleMaps)) {
        await launchUrl(googleMaps, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMaps)) {
        await launchUrl(appleMaps, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch maps: $e');
    }
  }

  // ── Ambulance ───────────────────────────────
  Future<void> _bookAmbulance(String userName) async {
    if (user == null) return;

    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (_) => _ConfirmDialog(
            title: 'Request Ambulance',
            message:
                'This will dispatch an emergency alert to nearby services. Are you sure you want to proceed?',
            confirmLabel: 'CONFIRM',
            confirmColor: _AppColors.danger,
          ),
        ) ??
        false;

    if (!confirm) return;

    await FirebaseFirestore.instance.collection('bookings').add({
      'patientId': user!.uid,
      'patientName': userName,
      'pickupAddress': 'Current Location (GPS)',
      'emergencyType': 'General Emergency',
      'priority': 'CRITICAL',
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.emergency_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Ambulance requested successfully',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: _AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── Scheme Modal ────────────────────────────
  void _showSchemeDetails(
    String title,
    String description,
    List<String> benefits,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SchemeBottomSheet(
        title: title,
        description: description,
        benefits: benefits,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Unable to load data. Please check your connection.'),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: _AppColors.primary),
            ),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final name = userData?['name'] as String? ?? 'User';
        final email = userData?['email'] as String? ?? user?.email ?? '';
        final profilePic = userData?['profileImage'] as String?;
        final patientId = userData?['patientId'] as String? ?? 'N/A';

        return Scaffold(
          backgroundColor: _AppColors.background,
          appBar: _buildAppBar(),
          drawer: _buildDrawer(userData, email, patientId),
          floatingActionButton: const SosButton(),
          body: RefreshIndicator(
            color: _AppColors.primary,
            onRefresh: () async => setState(() {}),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _PatientCard(
                        name: name,
                        email: email,
                        profilePic: profilePic,
                        patientId: patientId,
                      ),
                      const SizedBox(height: 32),
                      const _SectionLabel(label: 'EMERGENCY SERVICES'),
                      const SizedBox(height: 12),
                      _buildEmergencyServices(),
                      const SizedBox(height: 32),
                      const _SectionLabel(label: 'QUICK ACTIONS'),
                      const SizedBox(height: 12),
                      _buildQuickActions(name),
                      const SizedBox(height: 32),
                      const _SectionLabel(label: 'RECENT HISTORY'),
                      const SizedBox(height: 12),
                      _buildSurgeryHistory(),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── AppBar ───────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: _AppColors.divider,
      backgroundColor: _AppColors.surface,
      foregroundColor: _AppColors.primary,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: _AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'CareNexus',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: _AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _push(const ChatListPage()),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          tooltip: 'Messages',
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: logout,
          icon: const Icon(Icons.logout_rounded, color: _AppColors.danger),
          tooltip: 'Sign out',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Emergency Services Row ───────────────────
  Widget _buildEmergencyServices() {
    final services = [
      _ServiceData(
        'Hospitals',
        Icons.local_hospital_rounded,
        _AppColors.danger,
        () => _openNearby('hospital'),
      ),
      _ServiceData(
        'Ambulance',
        Icons.airport_shuttle_rounded,
        _AppColors.warning,
        () => _openNearby('ambulance'),
      ),
      _ServiceData(
        'Pharmacy',
        Icons.medication_liquid_rounded,
        _AppColors.success,
        () => _openNearby('pharmacy'),
      ),
      _ServiceData(
        'Labs',
        Icons.biotech_rounded,
        _AppColors.primaryLight,
        () => _openNearby('pathology lab'),
      ),
    ];

    return Row(
      children: services
          .map((s) => Expanded(child: _EmergencyServiceTile(data: s)))
          .toList(),
    );
  }

  // ── Quick Actions Grid ───────────────────────
  Widget _buildQuickActions(String name) {
    final actions = [
      _ActionData(
        'Doctor Chat',
        Icons.chat_rounded,
        _AppColors.primaryLight,
        () => _push(const ChatListPage()),
      ),
      _ActionData(
        'Medical Store',
        Icons.storefront_rounded,
        _AppColors.success,
        () => _push(const MedicalStorePage()),
      ),
      _ActionData(
        'Book Ambulance',
        Icons.emergency_share_rounded,
        _AppColors.danger,
        () => _bookAmbulance(name),
      ),
      _ActionData(
        'Health Records',
        Icons.folder_open_rounded,
        _AppColors.warning,
        () => _push(const HealthRecordsPage()),
      ),
      _ActionData(
        'Appointments',
        Icons.event_note_rounded,
        const Color(0xFF8B5CF6),
        () => _push(const AppointmentsPage()),
      ),
      _ActionData(
        'Govt Schemes',
        Icons.account_balance_rounded,
        const Color(0xFF0891B2),
        () => _push(const HospitalSchemesPage()),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, i) => _QuickActionTile(data: actions[i]),
    );
  }

  // ── Surgery History ──────────────────────────
  Widget _buildSurgeryHistory() {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.divider),
      ),
      child: Column(
        children: [
          _HistoryTile(
            procedure: 'Appendectomy',
            hospital: 'City Hospital',
            date: 'Mar 2024',
            isLast: false,
          ),
          _HistoryTile(
            procedure: 'Cataract Surgery',
            hospital: 'Eye Care Center',
            date: 'Jan 2023',
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ── Drawer ───────────────────────────────────
  Widget _buildDrawer(
    Map<String, dynamic>? userData,
    String email,
    String patientId,
  ) {
    return Drawer(
      backgroundColor: _AppColors.surface,
      child: Column(
        children: [
          _DrawerHeader(userData: userData, patientId: patientId),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    _push(const ProfilePage());
                  },
                ),
                _DrawerItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Appointments',
                  onTap: () {
                    Navigator.pop(context);
                    _push(const AppointmentsPage());
                  },
                ),
                _DrawerItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Messages',
                  onTap: () {
                    Navigator.pop(context);
                    _push(const ChatListPage());
                  },
                ),
                _DrawerItem(
                  icon: Icons.local_hospital_outlined,
                  label: 'Hospitals',
                  onTap: () {
                    Navigator.pop(context);
                    _push(const NearbyHospitalsPage());
                  },
                ),
                _DrawerItem(
                  icon: Icons.person_search_outlined,
                  label: 'Family Doctor',
                  onTap: () {
                    Navigator.pop(context);
                    _push(const FamilyDoctorPage());
                  },
                ),
                _DrawerItem(
                  icon: Icons.folder_shared_outlined,
                  label: 'Health Records',
                  onTap: () {
                    Navigator.pop(context);
                    _push(const HealthRecordsPage());
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(color: _AppColors.divider),
                ),
                _DrawerItem(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Donate Organ',
                  onTap: () {
                    Navigator.pop(context);
                    _push(const DonateOrganPage());
                  },
                ),
                _DrawerItem(
                  icon: Icons.add_box_outlined,
                  label: 'Request Organ',
                  onTap: () {
                    Navigator.pop(context);
                    _push(const RequestOrganPage());
                  },
                ),
                _DrawerItem(
                  icon: Icons.account_balance_outlined,
                  label: 'Govt Schemes',
                  onTap: () {
                    Navigator.pop(context);
                    _push(const HospitalSchemesPage());
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(color: _AppColors.divider),
                ),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  color: _AppColors.danger,
                  onTap: () {
                    Navigator.pop(context);
                    logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-Widgets
// ─────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final String name;
  final String email;
  final String? profilePic;
  final String patientId;

  const _PatientCard({
    required this.name,
    required this.email,
    required this.profilePic,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/card_pattern.png'),
          fit: BoxFit.cover,
          opacity: 0.07,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withOpacity(0.15),
                backgroundImage: profilePic != null
                    ? NetworkImage(profilePic!)
                    : null,
                child: profilePic == null
                    ? const Icon(Icons.person, color: Colors.white, size: 32)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: _AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Patient ID: $patientId',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Emergency Service Data + Tile ──────────────
class _ServiceData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ServiceData(this.label, this.icon, this.color, this.onTap);
}

class _EmergencyServiceTile extends StatelessWidget {
  final _ServiceData data;
  const _EmergencyServiceTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: _AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              data.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Data + Tile ───────────────────
class _ActionData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionData(this.label, this.icon, this.color, this.onTap);
}

class _QuickActionTile extends StatelessWidget {
  final _ActionData data;
  const _QuickActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _AppColors.divider),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.textPrimary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── History Tile ───────────────────────────────
class _HistoryTile extends StatelessWidget {
  final String procedure;
  final String hospital;
  final String date;
  final bool isLast;

  const _HistoryTile({
    required this.procedure,
    required this.hospital,
    required this.date,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: _AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      procedure,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(hospital, style: _AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: _AppColors.divider),
          ),
      ],
    );
  }
}

// ── Drawer Header ──────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String patientId;

  const _DrawerHeader({this.userData, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final profilePic = userData?['profileImage'] as String?;
    final name = userData?['name'] as String? ?? 'User';

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        24,
      ),
      color: _AppColors.primary,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            backgroundImage: profilePic != null
                ? NetworkImage(profilePic)
                : null,
            child: profilePic == null
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: $patientId',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer Item ────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? _AppColors.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: color ?? _AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ── Confirm Dialog ─────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: _AppTextStyles.heading2),
      content: Text(message, style: _AppTextStyles.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: _AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ── Scheme Bottom Sheet ────────────────────────
class _SchemeBottomSheet extends StatelessWidget {
  final String title;
  final String description;
  final List<String> benefits;

  const _SchemeBottomSheet({
    required this.title,
    required this.description,
    required this.benefits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: _AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: _AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: _AppTextStyles.heading2)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'About Scheme',
            style: _AppTextStyles.label.copyWith(
              color: _AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(description, style: _AppTextStyles.body),
          const SizedBox(height: 20),
          Text(
            'Key Benefits',
            style: _AppTextStyles.label.copyWith(
              color: _AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: _AppColors.success,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      b,
                      style: _AppTextStyles.body.copyWith(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply for Scheme',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
