import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

class ResponderAlertItem {
  ResponderAlertItem({
    required this.id,
    required this.referenceCode,
    required this.category,
    required this.title,
    required this.location,
    required this.distanceMeters,
    required this.reportedTime,
    required this.reporterName,
    required this.reporterPhone,
    required this.description,
    this.isAccepted = false,
    this.isArrived = false,
  });

  final String id;
  final String referenceCode;
  final String category;
  final String title;
  final String location;
  final int distanceMeters;
  final String reportedTime;
  final String reporterName;
  final String reporterPhone;
  final String description;
  bool isAccepted;
  bool isArrived;
}

class ResponderDashboardScreen extends StatefulWidget {
  const ResponderDashboardScreen({
    super.key,
    this.onOpenMap,
  });

  final void Function(double lat, double lng)? onOpenMap;

  @override
  State<ResponderDashboardScreen> createState() => _ResponderDashboardScreenState();
}

class _ResponderDashboardScreenState extends State<ResponderDashboardScreen> {
  bool _isOnDuty = true;

  final List<ResponderAlertItem> _alerts = [
    ResponderAlertItem(
      id: '1',
      referenceCode: 'SOS-2026-00124',
      category: 'medical',
      title: 'Medical Emergency (SOS Panic)',
      location: 'Student Center / Gymnasium',
      distanceMeters: 240,
      reportedTime: '3 mins ago',
      reporterName: 'Juan Dela Cruz',
      reporterPhone: '+63 917 456 1234',
      description: 'Student collapsed near basketball bleachers, breathing shallow. Immediate medical assistance required.',
    ),
    ResponderAlertItem(
      id: '2',
      referenceCode: 'INC-2026-00125',
      category: 'security',
      title: 'Security Incident',
      location: 'Main Gate 2 Perimeter',
      distanceMeters: 410,
      reportedTime: '12 mins ago',
      reporterName: 'Officer D. Torralba',
      reporterPhone: '+63 38 000 9112',
      description: 'Unauthorized trespasser spotted near boundary fence.',
    ),
    ResponderAlertItem(
      id: '3',
      referenceCode: 'INC-2026-00126',
      category: 'fire',
      title: 'Electrical Sparking Hazard',
      location: 'CCT Technology Bldg - Room 204',
      distanceMeters: 180,
      reportedTime: '24 mins ago',
      reporterName: 'Prof. Ana Reyes',
      reporterPhone: '+63 917 222 8890',
      description: 'Breaker box sparks and acrid odor detected.',
    ),
  ];

  static Future<void> _callReporter(BuildContext context, String phone) async {
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

  void _acceptIncident(ResponderAlertItem item) {
    setState(() {
      item.isAccepted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1976D2),
        content: Text('Incident ${item.referenceCode} accepted. You are now designated responder.'),
      ),
    );
  }

  void _markArrived(ResponderAlertItem item) {
    setState(() {
      item.isArrived = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF7B1FA2),
        content: Text('Status updated: Arrived on scene.'),
      ),
    );
  }

  void _resolveIncident(ResponderAlertItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resolve Incident?'),
        content: Text('Confirm resolution of ${item.referenceCode} at ${item.location}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              Navigator.pop(dialogCtx);
              setState(() {
                _alerts.remove(item);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF2E7D32),
                  content: Text('Incident marked as Resolved & closed.'),
                ),
              );
            },
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Responder Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Row(
            children: [
              Text(
                _isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _isOnDuty ? const Color(0xFF2E7D32) : Colors.grey,
                ),
              ),
              Switch(
                value: _isOnDuty,
                activeColor: const Color(0xFF2E7D32),
                onChanged: (val) => setState(() => _isOnDuty = val),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Officer Profile Card
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
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'RB',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Officer Ramon Bautista',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Campus Security • Badge EMP-2019-0044',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield, color: Color(0xFF2E7D32), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Active Alerts Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: AppColors.sos, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'ACTIVE DISPATCH QUEUE',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.sos.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_alerts.length} Active',
                    style: const TextStyle(
                      color: AppColors.sos,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // List of Alert Cards
            if (_alerts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 48),
                    SizedBox(height: 12),
                    Text(
                      'No Active Alerts Pending',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'All current campus sectors are clear and monitored.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = _alerts[index];
                  final bool isMedical = item.category == 'medical';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.isAccepted
                            ? const Color(0xFF1976D2)
                            : (isMedical ? AppColors.sos : const Color(0xFFED6C02)),
                        width: item.isAccepted ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isMedical ? '🔴' : (item.category == 'fire' ? '🔥' : '🟠'),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Distance: ${item.distanceMeters}m',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              item.location,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Colors.black45),
                            const SizedBox(width: 4),
                            Text(
                              'Reporter: ${item.reporterName} (${item.reporterPhone})',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                            const Spacer(),
                            Text(
                              item.reportedTime,
                              style: const TextStyle(fontSize: 11, color: Colors.black45),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Action Buttons based on state
                        if (!item.isAccepted) ...[
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isMedical ? AppColors.sos : const Color(0xFFED6C02),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _acceptIncident(item),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('ACCEPT INCIDENT', style: TextStyle(fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // After Accepting
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.navigation, color: Color(0xFF1976D2), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  item.isArrived ? 'On scene with reporter.' : 'Incident Accepted • Navigate to location.',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  if (widget.onOpenMap != null) {
                                    widget.onOpenMap!(9.718936, 124.110054);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Opening Campus Map route...')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.map_outlined, size: 16),
                                label: const Text('OPEN MAP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _callReporter(context, item.reporterPhone),
                                icon: const Icon(Icons.phone, size: 16),
                                label: const Text('CALL REPORTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              if (!item.isArrived)
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF7B1FA2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _markArrived(item),
                                  icon: const Icon(Icons.pin_drop, size: 16),
                                  label: const Text('MARK AS ARRIVED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              else
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _resolveIncident(item),
                                  icon: const Icon(Icons.check_circle, size: 16),
                                  label: const Text('RESOLVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
