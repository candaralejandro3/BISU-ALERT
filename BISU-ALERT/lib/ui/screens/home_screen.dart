import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/auth/auth_controller.dart';
import '../../data/auth/auth_scope.dart';
import '../../data/mock/mock_data.dart';
import '../../data/model/alert_message.dart';
import '../../data/model/app_user.dart';
import '../../data/services/sos_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/emergency_call_fallback_dialog.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/section_card.dart';
import '../widgets/sos_hold_button.dart';
import 'emergency_tracking_screen.dart';
import 'my_reports_screen.dart';
import 'notifications_screen.dart';
import 'responder_dashboard_screen.dart';

/// Tab indices in [MainShell], so the quick actions and the bottom bar cannot drift apart.
class HomeTab {
  const HomeTab._();

  static const int home = 0;
  static const int map = 1;
  static const int report = 2;
  static const int directory = 3;
  static const int profile = 4;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onNavigate});

  final void Function(int tab)? onNavigate;

  static Future<void> callNumber(BuildContext context, String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot place call to $phoneNumber.')),
      );
    }
  }

  String _timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    return '${diff.inHours}h ago';
  }

  void _go(BuildContext context, int tab, String name) {
    final void Function(int tab)? navigate = onNavigate;
    if (navigate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open $name from navigation.')),
      );
      return;
    }
    navigate(tab);
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _openMyReports(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyReportsScreen(
          onNewReport: () => _go(context, HomeTab.report, 'Report Incident'),
        ),
      ),
    );
  }

  void _openResponderDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResponderDashboardScreen(
          onOpenMap: (lat, lng) => _go(context, HomeTab.map, 'Campus Map'),
        ),
      ),
    );
  }

  void _openEmergencyTracking(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EmergencyTrackingScreen(
          onViewMap: () => _go(context, HomeTab.map, 'Campus Map'),
        ),
      ),
    );
  }

  Future<void> _handleSosTrigger(BuildContext context) async {
    final auth = AuthScope.of(context);
    final sos = SosController();

    if (auth.isOfflineSession) {
      // Direct call fallback
      EmergencyCallFallbackDialog.show(context);
      return;
    }

    // Trigger full SOS flow
    await sos.triggerSos(token: auth.token);

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EmergencyTrackingScreen(
            onViewMap: () => _go(context, HomeTab.map, 'Campus Map'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = AuthScope.of(context);
    final AppUser? user = auth.currentUser;
    final int criticalCount =
        MockData.activeAlerts.where((AlertMessage a) => a.isCritical).length;

    final sos = SosController();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              criticalCount: criticalCount,
              isOffline: auth.isOfflineSession,
              onOpenAlerts: () => _openNotifications(context),
            ),

            const SizedBox(height: 12),

            // Slogan Banner: "Stay alert. Help is available on campus."
            const _CampusSafetySloganBanner(),

            // Active Emergency Status Card (if ongoing)
            AnimatedBuilder(
              animation: sos,
              builder: (context, _) {
                if (!sos.hasActiveEmergency) return const SizedBox.shrink();
                final emergency = sos.currentEmergency!;

                return Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEF9A9A)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sos.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.sos,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emergency, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔴 Emergency Active • ${emergency.incidentId}',
                              style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Responder: ${emergency.responderName} (${emergency.status.label})',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sos,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () => _openEmergencyTracking(context),
                        child: const Text('Track', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),

            if (auth.isOfflineSession) ...[
              const SizedBox(height: 12),
              _OfflineSessionNotice(
                onSyncPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checking server connection and synchronizing queue...')),
                  );
                },
              ),
            ],

            const SizedBox(height: 16),

            // SOS Hold / Tap Button
            Center(
              child: SosHoldButton(
                onCompleted: () => _handleSosTrigger(context),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Hotlines Bar
            const _QuickHotlinesBar(),

            const SizedBox(height: 16),

            // Quick Actions Grid (Refined aspect ratio to eliminate text truncation)
            SectionCard(
              title: 'Quick Actions',
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  _QuickActionItem(
                    icon: Icons.warning_amber_rounded,
                    iconBgColor: AppColors.sos.withValues(alpha: 0.12),
                    iconColor: AppColors.sos,
                    label: 'Report Incident',
                    subLabel: 'Medical, Fire, Hazard',
                    onTap: () => _go(context, HomeTab.report, 'Report Incident'),
                  ),
                  _QuickActionItem(
                    icon: Icons.map_outlined,
                    iconBgColor: const Color(0xFF1976D2).withValues(alpha: 0.12),
                    iconColor: const Color(0xFF1976D2),
                    label: 'Campus Map',
                    subLabel: 'Safe zones & hubs',
                    onTap: () => _go(context, HomeTab.map, 'Campus Map'),
                  ),
                  _QuickActionItem(
                    icon: Icons.assignment_outlined,
                    iconBgColor: const Color(0xFF00897B).withValues(alpha: 0.12),
                    iconColor: const Color(0xFF00897B),
                    label: 'My Reports',
                    subLabel: 'Track filed incidents',
                    onTap: () => _openMyReports(context),
                  ),
                  _QuickActionItem(
                    icon: Icons.phone_in_talk_outlined,
                    iconBgColor: AppColors.primary.withValues(alpha: 0.12),
                    iconColor: AppColors.primary,
                    label: 'Directory',
                    subLabel: 'Clinic & Security',
                    onTap: () => _go(context, HomeTab.directory, 'Emergency Directory'),
                  ),
                  _QuickActionItem(
                    icon: Icons.campaign_outlined,
                    iconBgColor: AppColors.secondary.withValues(alpha: 0.15),
                    iconColor: const Color(0xFFD97706),
                    label: 'Announcements',
                    subLabel: 'Safety bulletins',
                    onTap: () => _openNotifications(context),
                  ),
                  _QuickActionItem(
                    icon: Icons.security_rounded,
                    iconBgColor: const Color(0xFF7B1FA2).withValues(alpha: 0.12),
                    iconColor: const Color(0xFF7B1FA2),
                    label: user?.role == CampusRole.security ? 'Responder Mode' : 'Responder View',
                    subLabel: 'Security dispatch',
                    onTap: () => _openResponderDashboard(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Active Alerts Feed
            SectionCard(
              title: 'Active Alerts Feed',
              trailing: TextButton(
                onPressed: () => _openNotifications(context),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('View All'),
              ),
              child: Column(
                children: MockData.activeAlerts
                    .map((alert) => _AlertTile(
                          alert: alert,
                          timeAgo: _timeAgo,
                          onTap: () => _openNotifications(context),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.criticalCount,
    required this.isOffline,
    required this.onOpenAlerts,
  });

  final int criticalCount;
  final bool isOffline;
  final VoidCallback onOpenAlerts;

  String _greeting() {
    return switch (DateTime.now().hour) {
      < 12 => 'Good morning',
      < 18 => 'Good afternoon',
      _ => 'Good evening',
    };
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppUser? user = AuthScope.of(context).currentUser;

    final String name = user != null ? user.firstName : 'Visitor';
    final String greetingText = '${_greeting()}, $name';

    return Row(
      children: [
        const AppLogo(size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'BISU Bilar Campus',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOffline ? AppColors.secondary : const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      greetingText,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (user != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.role.label,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onOpenAlerts,
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: criticalCount > 0,
            label: Text('$criticalCount'),
            backgroundColor: AppColors.sos,
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
        const _AccountMenuButton(),
      ],
    );
  }
}

/// Slogan Banner replacing any accidental closure or debug text with clear reassuring guidance
class _CampusSafetySloganBanner extends StatelessWidget {
  const _CampusSafetySloganBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFF2E7D32), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '“Stay alert. Help is available on campus.”',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sophisticated Offline Mode banner with checklist of offline capabilities & sync queue counter
class _OfflineSessionNotice extends StatelessWidget {
  const _OfflineSessionNotice({this.onSyncPressed});

  final VoidCallback? onSyncPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_off_rounded, size: 20, color: Color(0xFFB78103)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Offline Session Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF7A5500),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECB3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '3 reports waiting to sync',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF7A5500)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '✓ View emergency contacts\n✓ View cached campus map\n✓ View saved safety guides\n✓ Direct call emergency numbers\n✓ Prepare incident report & save locally',
            style: TextStyle(
              color: Color(0xFF664800),
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB78103),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => HomeScreen.callNumber(context, '+63 38 000 9112'),
                  icon: const Icon(Icons.phone, size: 15),
                  label: const Text(
                    'Call Security: (038) 000-9112',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7A5500),
                  side: const BorderSide(color: Color(0xFFB78103)),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onSyncPressed,
                icon: const Icon(Icons.sync, size: 15),
                label: const Text('Sync Now', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickHotlinesBar extends StatelessWidget {
  const _QuickHotlinesBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _HotlineButton(
              label: 'Security Post',
              subLabel: '(038) 000-9112',
              icon: Icons.shield_outlined,
              iconColor: AppColors.primary,
              onTap: () => HomeScreen.callNumber(context, '+63 38 000 9112'),
            ),
          ),
          Container(
            height: 28,
            width: 1,
            color: Colors.black12,
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),
          Expanded(
            child: _HotlineButton(
              label: 'Campus Clinic',
              subLabel: '(038) 000-9111',
              icon: Icons.local_hospital_outlined,
              iconColor: AppColors.sos,
              onTap: () => HomeScreen.callNumber(context, '+63 38 000 9111'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HotlineButton extends StatelessWidget {
  const _HotlineButton({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final String subLabel;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subLabel,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountMenuButton extends StatelessWidget {
  const _AccountMenuButton();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppUser? user = AuthScope.of(context).currentUser;

    if (user == null) {
      return IconButton(
        onPressed: () {},
        icon: const Icon(Icons.account_circle_outlined),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      icon: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          user.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      onSelected: (String value) {
        if (value == 'logout') {
          confirmSignOut(context, AuthScope.read(context));
        } else if (value == 'reports') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MyReportsScreen()),
          );
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(user.email, style: textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(user.role.label, style: textTheme.bodySmall),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'reports',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.assignment_outlined, color: AppColors.primary),
            title: Text('My Reports'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: AppColors.sos),
            title: Text('Log Out'),
          ),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.subLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String subLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(14);

    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    required this.timeAgo,
    this.onTap,
  });

  final AlertMessage alert;
  final String Function(DateTime) timeAgo;
  final VoidCallback? onTap;

  IconData _iconForAlert() {
    final String lower = alert.title.toLowerCase();
    if (alert.isCritical || lower.contains('medical') || lower.contains('danger') || lower.contains('active')) {
      return Icons.error_outline_rounded;
    }
    if (lower.contains('weather') || lower.contains('rain') || lower.contains('typhoon')) {
      return Icons.wb_cloudy_outlined;
    }
    return Icons.campaign_outlined;
  }

  Color _colorForAlert() {
    if (alert.isCritical) return AppColors.sos;
    final String lower = alert.title.toLowerCase();
    if (lower.contains('weather')) return const Color(0xFF0288D1);
    return const Color(0xFFD97706);
  }

  String _badgeText() {
    if (alert.isCritical) return 'CRITICAL';
    final String lower = alert.title.toLowerCase();
    if (lower.contains('weather')) return 'WEATHER';
    return 'CAMPUS';
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _colorForAlert();
    final String tag = _badgeText();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alert.isCritical
              ? accentColor.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: alert.isCritical
                ? accentColor.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _iconForAlert(),
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 11,
                                color: Colors.black45,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                timeAgo(alert.timestamp),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        alert.detail,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
