import 'package:flutter/material.dart';

import '../../data/auth/auth_controller.dart';
import '../../data/auth/auth_scope.dart';
import '../../data/model/app_user.dart';
import 'account_settings_screen.dart';
import 'emergency_information_screen.dart';
import 'emergency_settings_screen.dart';
import 'notifications_settings_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = AuthScope.of(context);
    final AppUser? user = auth.currentUser;

    final String displayName =
        user != null && user.fullName.trim().isNotEmpty
            ? user.fullName
            : 'Juan Dela Cruz';

    final String roleAndDept = user != null
        ? '${user.role.label} • ${user.department.trim().isNotEmpty ? user.department : 'BSCS'}'
        : 'Student • BSCS';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ===============================================================
              // Header: User Avatar, Name, Role/Dept & Settings Icon
              // ===============================================================
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E6F38),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          roleAndDept,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Color(0xFF334155),
                      size: 26,
                    ),
                    tooltip: 'Account Settings',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AccountSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ===============================================================
              // 1. Emergency Information Card
              // ===============================================================
              _DashboardNavCard(
                icon: Icons.groups_rounded,
                iconBgColor: const Color(0xFFE11D48),
                title: 'Emergency Information',
                subtitle: 'ICE Contact & Medical Info',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmergencyInformationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // ===============================================================
              // 2. Emergency Settings Card
              // ===============================================================
              _DashboardNavCard(
                icon: Icons.shield_outlined,
                iconBgColor: const Color(0xFFEA580C),
                title: 'Emergency Settings',
                subtitle: 'Siren • Flashlight • Geofence Alerts',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmergencySettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // ===============================================================
              // 3. Notifications Card
              // ===============================================================
              _DashboardNavCard(
                icon: Icons.notifications_rounded,
                iconBgColor: const Color(0xFF2563EB),
                title: 'Notifications',
                subtitle: 'Push & Weather Alerts',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsSettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // ===============================================================
              // 4. Account Card
              // ===============================================================
              _DashboardNavCard(
                icon: Icons.person_rounded,
                iconBgColor: const Color(0xFF7C3AED),
                title: 'Account',
                subtitle: 'Password • Tutorial • Logout',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardNavCard extends StatelessWidget {
  const _DashboardNavCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: iconBgColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
