import 'package:flutter/material.dart';

import '../../data/services/profile_data_service.dart';
import '../theme/app_colors.dart';

class EmergencySettingsScreen extends StatefulWidget {
  const EmergencySettingsScreen({super.key});

  @override
  State<EmergencySettingsScreen> createState() => _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends State<EmergencySettingsScreen> {
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
            Text('Emergency Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'These settings determine device hardware actions and alert boundaries during active campus emergency triage and SOS triggers.',
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
        title: const Text('Emergency Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Emergency Settings',
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
                    value: _service.sirenEnabled,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.volume_up_rounded, color: Color(0xFFE11D48)),
                    ),
                    title: const Text(
                      'Sound Loud Siren on SOS',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: const Text(
                      'Audible alarm from device speaker to alert nearby people.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) async {
                      await _service.setEmergencySettings(siren: val);
                      setState(() {});
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _service.flashlightStrobeEnabled,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flashlight_on_rounded, color: Color(0xFFEA580C)),
                    ),
                    title: const Text(
                      'Flashlight Strobe Signal',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: const Text(
                      'Flashes phone LED strobe light for rapid visual location.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) async {
                      await _service.setEmergencySettings(flashlight: val);
                      setState(() {});
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _service.geofenceAlertsEnabled,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7)),
                    ),
                    title: const Text(
                      'Campus Geofenced Incident Alerts',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: const Text(
                      'Notify me if an incident happens near my current building.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) async {
                      await _service.setEmergencySettings(geofence: val);
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
