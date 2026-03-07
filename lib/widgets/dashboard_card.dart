import 'dart:ui';
import 'package:flutter/material.dart';

enum HealthcareCardType {
  appointment,
  reports,
  ambulance,
  pharmacy,
  consultation,
}

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final HealthcareCardType type;

  const DashboardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.type,
    this.onTap,
  });

  Color _healthcareColor() {
    switch (type) {
      case HealthcareCardType.appointment:
        return const Color(0xFF2563EB); // Blue
      case HealthcareCardType.reports:
        return const Color(0xFF0EA5E9); // Sky
      case HealthcareCardType.ambulance:
        return const Color(0xFFDC2626); // Emergency red
      case HealthcareCardType.pharmacy:
        return const Color(0xFF16A34A); // Green
      case HealthcareCardType.consultation:
        return const Color(0xFF4F46E5); // Indigo
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _healthcareColor();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [Colors.white, Colors.grey.shade50],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 30, color: accent),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
