import 'package:flutter/material.dart';

import '../../data/services/profile_data_service.dart';
import '../theme/app_colors.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final ProfileDataService _service = ProfileDataService();

  @override
  void initState() {
    super.initState();
    _service.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Notifications Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Manage the real-time broadcast and weather bulletin feeds you receive on your device.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Notifications',
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: _service.pushNotificationsEnabled,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF2563EB)),
                    ),
                    title: const Text(
                      'Push Notifications',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: const Text(
                      'Receive official campus emergency and safety broadcasts.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) async {
                      await _service.setNotificationSettings(push: val);
                      setState(() {});
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _service.weatherAdvisoriesEnabled,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_rounded, color: Color(0xFF0D9488)),
                    ),
                    title: const Text(
                      'PAGASA & MDRRMO Weather Advisories',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: const Text(
                      'Typhoon alerts and heavy rainfall warnings.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) async {
                      await _service.setNotificationSettings(weather: val);
                      setState(() {});
                    },
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
