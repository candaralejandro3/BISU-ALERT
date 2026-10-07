import 'package:flutter/material.dart';

import '../../data/services/incident_api_service.dart';
import '../theme/app_colors.dart';
import 'incident_detail_screen.dart';

enum ReportStatusFilter { all, active, resolved }

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key, this.onNewReport});

  final VoidCallback? onNewReport;

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  ReportStatusFilter _selectedFilter = ReportStatusFilter.all;

  // Curated sample user reports spanning all required statuses
  final List<Incident> _reports = [
    Incident(
      id: '102',
      referenceCode: 'INC-001',
      category: 'medical',
      severity: 'Critical',
      location: 'Student Center / Gymnasium',
      latitude: 9.718936,
      longitude: 124.110054,
      description: 'Student collapsed near basketball bleachers, medical response active.',
      isAnonymous: false,
      status: 'responding',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    Incident(
      id: '100',
      referenceCode: 'INC-002',
      category: 'facility_damage',
      severity: 'Normal',
      location: 'College of Engineering & Architecture (CEA)',
      latitude: 9.718041,
      longitude: 124.109602,
      description: 'Broken window pane on 2nd floor drafting room replaced and secured.',
      isAnonymous: false,
      status: 'resolved',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    Incident(
      id: '101',
      referenceCode: 'INC-003',
      category: 'security',
      severity: 'High',
      location: 'Main Gate 2 Guardhouse',
      latitude: 9.718314,
      longitude: 124.111249,
      description: 'Unauthorized individual trying to bypass campus visitor log.',
      isAnonymous: false,
      status: 'under_review',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Incident(
      id: '99',
      referenceCode: 'INC-004',
      category: 'fire_hazard',
      severity: 'Moderate',
      location: 'CAF Extension Laboratory',
      latitude: 9.720121,
      longitude: 124.106403,
      description: 'Chemical storage cabinet latch malfunctioning.',
      isAnonymous: false,
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Incident(
      id: '97',
      referenceCode: 'INC-005',
      category: 'accident',
      severity: 'Low',
      location: 'Main Driveway Parking Area',
      latitude: 9.718500,
      longitude: 124.110500,
      description: 'Minor bumper contact between two motorcycles in lot.',
      isAnonymous: true,
      status: 'cancelled',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  List<Incident> get _filteredReports {
    return switch (_selectedFilter) {
      ReportStatusFilter.all => _reports,
      ReportStatusFilter.active => _reports
          .where((r) =>
              r.status == 'pending' ||
              r.status == 'under_review' ||
              r.status == 'acknowledged' ||
              r.status == 'responding')
          .toList(),
      ReportStatusFilter.resolved => _reports
          .where((r) => r.status == 'resolved' || r.status == 'cancelled')
          .toList(),
    };
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        label = 'Pending';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'under_review':
      case 'acknowledged':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1976D2);
        label = 'Under Review';
        icon = Icons.visibility_outlined;
        break;
      case 'responding':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        label = 'Responding';
        icon = Icons.run_circle_outlined;
        break;
      case 'resolved':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'Resolved';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
      default:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(Incident incident) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IncidentDetailScreen(
          incidentId: incident.id,
          initialIncident: incident,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReports;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All Reports (${_reports.length})',
                  isSelected: _selectedFilter == ReportStatusFilter.all,
                  onSelected: () => setState(() => _selectedFilter = ReportStatusFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  isSelected: _selectedFilter == ReportStatusFilter.active,
                  onSelected: () => setState(() => _selectedFilter = ReportStatusFilter.active),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Resolved',
                  isSelected: _selectedFilter == ReportStatusFilter.resolved,
                  onSelected: () => setState(() => _selectedFilter = ReportStatusFilter.resolved),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List of Reports
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No reports found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Incidents you submit will appear here.',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _ReportCard(
                        incident: item,
                        statusBadge: _buildStatusBadge(item.status),
                        onTap: () => _openDetail(item),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onNewReport ?? () => Navigator.pop(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('File Report', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : Colors.black87,
      ),
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      backgroundColor: Colors.grey.shade100,
      visualDensity: VisualDensity.compact,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.transparent,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.incident,
    required this.statusBadge,
    required this.onTap,
  });

  final Incident incident;
  final Widget statusBadge;
  final VoidCallback onTap;

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} • ${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          incident.referenceCode.isNotEmpty
                              ? incident.referenceCode
                              : 'INC-${incident.id}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        incident.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  statusBadge,
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: Colors.black54),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      incident.location,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                incident.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(incident.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  const Row(
                    children: [
                      Text(
                        'View Timeline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 14, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
