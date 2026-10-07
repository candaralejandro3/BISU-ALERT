import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/sms_alert_service.dart';
import '../theme/app_colors.dart';

/// Shows an emergency call fallback dialog when the backend server is unreachable or offline
class EmergencyCallFallbackDialog extends StatelessWidget {
  const EmergencyCallFallbackDialog({
    super.key,
    this.latitude = 9.71888,
    this.longitude = 124.10883,
  });

  final double latitude;
  final double longitude;

  static Future<void> show(BuildContext context, {double lat = 9.71888, double lng = 124.10883}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmergencyCallFallbackDialog(latitude: lat, longitude: lng),
    );
  }

  static Future<void> _dial(BuildContext context, String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot place call to $phone.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: AppColors.sos, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Server Unreachable — Direct Call Fallback',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.phone_forwarded, color: Color(0xFFE65100), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live server could not be reached. Connecting directly via campus telephone hotline.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFE65100), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select Campus Responder to Call Immediately:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54),
            ),
            const SizedBox(height: 10),

            // Hotline 1: Security Post
            _FallbackCallButton(
              title: 'BISU Campus Security Post',
              subtitle: 'Lead Guardhouse & Incident Dispatch',
              phone: '+63 38 000 9112',
              icon: Icons.shield_outlined,
              buttonColor: AppColors.primary,
              onPressed: () => _dial(context, '+63 38 000 9112'),
            ),

            const SizedBox(height: 8),

            // Hotline 2: University Clinic
            _FallbackCallButton(
              title: 'BISU University Clinic',
              subtitle: 'Emergency Medical & Nurse Station',
              phone: '+63 38 000 9111',
              icon: Icons.local_hospital_outlined,
              buttonColor: AppColors.sos,
              onPressed: () => _dial(context, '+63 38 000 9111'),
            ),

            const SizedBox(height: 8),

            // Hotline 3: Municipal MDRRMO
            _FallbackCallButton(
              title: 'Bilar Municipal Disaster (MDRRMO)',
              subtitle: 'Ambulance & Fire Rescue',
              phone: '+63 38 500 1300',
              icon: Icons.fire_truck_outlined,
              buttonColor: const Color(0xFFF57C00),
              onPressed: () => _dial(context, '+63 38 500 1300'),
            ),

            const SizedBox(height: 12),

            // SMS Dispatch option
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                SmsAlertService.sendSosAlert(
                  phoneNumber: '+63380009112',
                  latitude: latitude,
                  longitude: longitude,
                );
              },
              icon: const Icon(Icons.sms_outlined, size: 16),
              label: const Text('Send Offline SMS Dispatch with GPS', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}

class _FallbackCallButton extends StatelessWidget {
  const _FallbackCallButton({
    required this.title,
    required this.subtitle,
    required this.phone,
    required this.icon,
    required this.buttonColor,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String phone;
  final IconData icon;
  final Color buttonColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: buttonColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: buttonColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onPressed,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, size: 13),
                  SizedBox(width: 4),
                  Text('Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
