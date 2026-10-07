import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/sos_alarm_service.dart';
import '../../data/services/sos_controller.dart';
import '../theme/app_colors.dart';

class EmergencyTrackingScreen extends StatefulWidget {
  const EmergencyTrackingScreen({
    super.key,
    this.onViewMap,
    this.onDismiss,
  });

  final VoidCallback? onViewMap;
  final VoidCallback? onDismiss;

  @override
  State<EmergencyTrackingScreen> createState() => _EmergencyTrackingScreenState();
}

class _EmergencyTrackingScreenState extends State<EmergencyTrackingScreen> {
  final SosController _sosController = SosController();

  static Future<void> _callHotline(BuildContext context, String phone) async {
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

  void _showCancelDialog(BuildContext context) {
    String selectedReason = 'Accidental activation / False alarm';

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.sos, size: 28),
              SizedBox(width: 10),
              Text('Cancel Emergency?', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to cancel this emergency request? Responders will be notified to stand down.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text(
                'Select Reason:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Accidental activation / False alarm',
                    child: Text('Accidental activation / False alarm', style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: 'Situation already resolved',
                    child: Text('Situation already resolved', style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: 'Assistance no longer needed',
                    child: Text('Assistance no longer needed', style: TextStyle(fontSize: 12)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedReason = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Keep Active'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.sos),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _sosController.cancelEmergency(reason: selectedReason);
                if (widget.onDismiss != null) {
                  widget.onDismiss!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Cancel Alert'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sosController,
      builder: (context, _) {
        final emergency = _sosController.currentEmergency;

        if (emergency == null ||
            emergency.status == EmergencyStatus.cancelled ||
            emergency.status == EmergencyStatus.resolved) {
          return Scaffold(
            appBar: AppBar(title: const Text('Emergency Tracking')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No Active Emergency',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All campus emergencies are currently standing down.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      if (widget.onDismiss != null) {
                        widget.onDismiss!();
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Return to Home'),
                  ),
                ],
              ),
            ),
          );
        }

        final bool isResponding = emergency.status == EmergencyStatus.responding;
        final String statusHeader = isResponding ? 'Help is on the way' : 'Emergency Alert Active';
        final String statusSub = isResponding
            ? 'Campus Security unit dispatched and en route to your location.'
            : 'Your location has been sent to Campus Security.';

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Active Emergency'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                if (widget.onDismiss != null) {
                  widget.onDismiss!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            actions: [
              ValueListenableBuilder<bool>(
                valueListenable: SosAlarmService().isActive,
                builder: (context, isSirenOn, _) {
                  return IconButton(
                    tooltip: isSirenOn ? 'Mute Siren' : 'Unmute Siren',
                    icon: Icon(
                      isSirenOn ? Icons.volume_up : Icons.volume_off,
                      color: isSirenOn ? AppColors.sos : Colors.grey,
                    ),
                    onPressed: () {
                      if (isSirenOn) {
                        SosAlarmService().stop();
                      } else {
                        SosAlarmService().start();
                      }
                    },
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Pulsing Emergency Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFC2185B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sos.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.emergency, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusHeader,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  statusSub,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'STATUS: ${emergency.status.label}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                emergency.etaMinutes > 0
                                    ? 'ETA: ~${emergency.etaMinutes} min'
                                    : 'ETA: Arriving',
                                style: const TextStyle(
                                  color: Color(0xFFC2185B),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Telemetry Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Incident Telemetry & Dispatch',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Incident ID',
                        value: emergency.incidentId,
                        isBold: true,
                        valueColor: AppColors.primary,
                      ),
                      _DetailRow(label: 'Type', value: emergency.type),
                      _DetailRow(label: 'Location', value: emergency.location),
                      _DetailRow(
                        label: 'Campus Geofence',
                        value: emergency.isInsideCampus
                            ? 'Inside BISU Bilar Campus ✓'
                            : 'Near Campus Boundary',
                        valueColor: emergency.isInsideCampus
                            ? const Color(0xFF2E7D32)
                            : Colors.orange.shade800,
                      ),
                      _DetailRow(
                        label: 'Reported',
                        value:
                            '${emergency.reportedAt.hour % 12 == 0 ? 12 : emergency.reportedAt.hour % 12}:${emergency.reportedAt.minute.toString().padLeft(2, '0')} ${emergency.reportedAt.hour >= 12 ? 'PM' : 'AM'}',
                      ),
                      _DetailRow(
                        label: 'Assigned Responder',
                        value: emergency.responderName,
                        isBold: true,
                      ),
                      _DetailRow(
                        label: 'Location Shared',
                        value: 'Live GPS Active ✓',
                        valueColor: const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (widget.onViewMap != null) {
                      widget.onViewMap!();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening live campus map tracking...')),
                      );
                    }
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('View Responder Location', style: TextStyle(fontWeight: FontWeight.w700)),
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _callHotline(context, emergency.responderPhone),
                  icon: const Icon(Icons.phone),
                  label: Text('Call Security: ${emergency.responderPhone}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),

                const SizedBox(height: 10),

                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.sos,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () => _showCancelDialog(context),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Emergency', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
