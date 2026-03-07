import 'dart:async';
import 'package:care_nexus/chats/ChatListPage.dart';
import 'package:care_nexus/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Internal Project Imports
import 'package:care_nexus/doctor/live_health_graph.dart';
import '../auth/login_page.dart';
import 'ReportsPage.dart';

// ─────────────────────────────────────────────
// Design Tokens (shared with PatientDashboard)
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

  // e-Yantra Premium Colors
  static const eYantraGradientStart = Color(0xFF6366F1);
  static const eYantraGradientEnd = Color(0xFF3B82F6);
}

class _AppTextStyles {
  static const heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: _AppColors.textPrimary,
    letterSpacing: -0.3,
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
class ProfessionalDoctorDashboard extends StatefulWidget {
  const ProfessionalDoctorDashboard({super.key});

  @override
  State<ProfessionalDoctorDashboard> createState() =>
      _ProfessionalDoctorDashboardState();
}

class _ProfessionalDoctorDashboardState
    extends State<ProfessionalDoctorDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isAvailable = true;
  int _unreadCount = 0;
  StreamSubscription? _unreadSub;

  @override
  void initState() {
    super.initState();
    _listenUnreadMessages();
  }

  void _listenUnreadMessages() {
    if (user == null) return;
    _unreadSub = FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: user!.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snap) {
          if (mounted) setState(() => _unreadCount = snap.docs.length);
        });
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  String get _firstName => user?.displayName?.split(' ').first ?? 'Specialist';

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      drawer: _buildDrawer(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _SectionLabel(label: 'SYSTEM ANALYTICS'),
                const SizedBox(height: 12),
                _buildAnalyticsRow(),
                const SizedBox(height: 32),
                const _SectionLabel(
                  label: 'EMERGENCY MONITOR',
                  color: _AppColors.danger,
                ),
                const SizedBox(height: 12),
                _buildSOSMonitor(),
                const SizedBox(height: 32),
                const _SectionLabel(label: 'CLINICAL OPERATIONS'),
                const SizedBox(height: 12),
                _buildOperationsGrid(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver Header ────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _AppColors.primary,
      surfaceTintColor: _AppColors.primary,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        // ── Chat with badge ─────────────────
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.monitor_heart_sharp, color: Colors.white),
              tooltip: 'E-Yantra Live Vitals',
              onPressed: () => _push(const LiveHealthGraph()),
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 6,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: _AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        _AvailabilityToggle(
          isAvailable: _isAvailable,
          onChanged: (val) => setState(() => _isAvailable = val),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: _AppColors.primary,
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 20),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _isAvailable
                            ? _AppColors.accent
                            : _AppColors.textSecondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: _AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dr. $_firstName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
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
                      user?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Analytics Row ────────────────────────────
  Widget _buildAnalyticsRow() {
    return Row(
      children: [
        _StatCard(
          label: 'Patients',
          value: '24',
          icon: Icons.people_outline_rounded,
          color: _AppColors.primaryLight,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Queue',
          value: '05',
          icon: Icons.hourglass_bottom_rounded,
          color: _AppColors.warning,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Revenue',
          value: '₹12k',
          icon: Icons.payments_outlined,
          color: _AppColors.success,
        ),
      ],
    );
  }

  // ── SOS Monitor ──────────────────────────────
  Widget _buildSOSMonitor() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: _AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All systems clear',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text('No active emergency alerts', style: _AppTextStyles.caption),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _AppColors.success,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Operations Grid ──────────────────────────
  Widget _buildOperationsGrid() {
    final actions = [
      _ActionData(
        'Patient History',
        Icons.folder_shared_outlined,
        _AppColors.primaryLight,
        () {},
      ),
      _ActionData(
        'Patient Chats',
        Icons.chat_bubble_outline_rounded,
        const Color(0xFF0891B2),
        () => _push(const ChatListPage()),
      ),
      _ActionData(
        'Reports',
        Icons.analytics_outlined,
        const Color(0xFF64748B),
        () {},
      ),
      _ActionData(
        'Tele-Med',
        Icons.videocam_outlined,
        const Color(0xFF0D9488),
        () {},
      ),
      _ActionData(
        'E-Prescribe',
        Icons.draw_outlined,
        _AppColors.warning,
        () {},
      ),
      _ActionData(
        'Scheduler',
        Icons.calendar_month_outlined,
        const Color(0xFF8B5CF6),
        () {},
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
      itemBuilder: (_, i) => _OperationTile(data: actions[i]),
    );
  }

  // ── Drawer ───────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _AppColors.surface,
      child: Column(
        children: [
          _DrawerHeader(user: user),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Patient Messages',
                  badge: _unreadCount > 0 ? '$_unreadCount' : null,
                  onTap: () {
                    Navigator.pop(context);
                    _push(const ChatListPage());
                  },
                ),

                _DrawerItem(
                  icon: Icons.folder_shared_outlined,
                  label: 'Patient History',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.analytics_outlined,
                  label: 'Reports',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.videocam_outlined,
                  label: 'Tele-Medicine',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.draw_outlined,
                  label: 'E-Prescribe',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Scheduler',
                  onTap: () => Navigator.pop(context),
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
                    _logout();
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
// Real-time e-Yantra Vitals Stream Component
// ─────────────────────────────────────────────
class _EYantraVitalsStream extends StatelessWidget {
  final String userId;

  const _EYantraVitalsStream({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('vitals')
          .where('doctorId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE63946).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE63946).withOpacity(0.3),
              ),
            ),
            child: const Text(
              'Unable to load vital records',
              style: TextStyle(color: Color(0xFFE63946), fontSize: 12),
            ),
          );
        }

        final vitals = snapshot.data?.docs ?? [];

        if (vitals.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Center(
              child: Text(
                'No vital records yet',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: List.generate(
            vitals.length,
            (index) =>
                _VitalCard(data: vitals[index].data() as Map<String, dynamic>),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Vital Card Component
// ─────────────────────────────────────────────
class _VitalCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _VitalCard({required this.data});

  Color _getStatusColor(String type, dynamic value) {
    if (type == 'bloodPressure') {
      final parts = value.toString().split('/');
      if (parts.length == 2) {
        final systolic = int.tryParse(parts[0]) ?? 0;
        if (systolic > 140) return const Color(0xFFE63946);
        if (systolic < 90) return const Color(0xFFF4A261);
        return const Color(0xFF2DC653);
      }
    } else if (type == 'spo2') {
      final spo2 = int.tryParse(value.toString()) ?? 0;
      if (spo2 < 95) return const Color(0xFFE63946);
      if (spo2 < 98) return const Color(0xFFF4A261);
      return const Color(0xFF2DC653);
    }
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final patientName = data['patientName'] ?? 'Unknown Patient';
    final bp = data['bloodPressure'] ?? '--';
    final spo2 = data['spo2'] ?? '--';
    final heartRate = data['heartRate'] ?? '--';
    final timestamp = data['timestamp'] as Timestamp?;

    final timeString = timestamp != null
        ? _formatTime(timestamp.toDate())
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Patient Name & Time ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  patientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeString,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Vital Indicators (SpO2 and BPM only) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _VitalIndicator(
                label: 'SpO₂',
                value: spo2.toString(),
                unit: '%',
                color: _getStatusColor('spo2', spo2),
                icon: Icons.air_rounded,
              ),
              const SizedBox(width: 40),
              _VitalIndicator(
                label: 'BPM',
                value: heartRate.toString(),
                unit: 'bpm',
                color: const Color(0xFF0891B2),
                icon: Icons.favorite_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

// ─────────────────────────────────────────────
// Vital Indicator Component
// ─────────────────────────────────────────────
class _VitalIndicator extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _VitalIndicator({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(unit, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Sub-Widgets
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;
  const _SectionLabel({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color ?? _AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AppColors.divider),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Operation Tile ─────────────────────────────
class _ActionData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionData(this.label, this.icon, this.color, this.onTap);
}

class _OperationTile extends StatelessWidget {
  final _ActionData data;
  const _OperationTile({required this.data});

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

// ── Availability Toggle ────────────────────────
class _AvailabilityToggle extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const _AvailabilityToggle({
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? _AppColors.accent.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isAvailable ? 'LIVE' : 'OFF',
            style: TextStyle(
              color: isAvailable ? _AppColors.accent : Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: isAvailable,
              activeColor: _AppColors.accent,
              activeTrackColor: _AppColors.accent.withOpacity(0.3),
              inactiveThumbColor: Colors.white60,
              inactiveTrackColor: Colors.white12,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer Header ──────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final User? user;
  const _DrawerHeader({this.user});

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: Colors.white.withOpacity(0.15),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${user?.displayName?.split(' ').first ?? 'Specialist'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
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
  final String? badge;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badge,
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
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _AppColors.danger,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
