import 'package:flutter/material.dart';

import '../../data/services/incident_api_service.dart';
import '../widgets/incident_status_tracker.dart';

/// Screen to display detailed incident information and status
class IncidentDetailScreen extends StatefulWidget {
  final String incidentId;
  final Incident? initialIncident;

  const IncidentDetailScreen({
    super.key,
    required this.incidentId,
    this.initialIncident,
  });

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final IncidentApiService _incidentService = IncidentApiService();
  late Future<Incident> _incidentFuture;
  late Future<IncidentStatusResponse> _statusFuture;

  @override
  void initState() {
    super.initState();
    _incidentFuture = _incidentService.getIncident(widget.incidentId);
    _statusFuture = _incidentService.getIncidentStatus(widget.incidentId);
  }

  String _getSeverityColor(String severity) {
    return switch (severity.toLowerCase()) {
      'critical' => '🔴',
      'medium' => '🟠',
      'low' => '🟢',
      _ => '⚪',
    };
  }

  String _getCategoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'medical' => '🏥',
      'fire' => '🔥',
      'crime' => '🚨',
      'disaster' => '⚠️',
      _ => '📌',
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        elevation: 0,
      ),
      body: FutureBuilder<Incident>(
        future: _incidentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading incident details',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => setState(() {
                      _incidentFuture =
                          _incidentService.getIncident(widget.incidentId);
                      _statusFuture =
                          _incidentService.getIncidentStatus(widget.incidentId);
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No incident data found'),
            );
          }

          final incident = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: incident.status.toLowerCase() == 'resolved'
                        ? Colors.green.withValues(alpha: 0.2)
                        : incident.status.toLowerCase() == 'dispatched'
                            ? Colors.blue.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${incident.status.toUpperCase()} • ${_formatDate(incident.createdAt)}',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: incident.status.toLowerCase() == 'resolved'
                          ? Colors.green
                          : incident.status.toLowerCase() == 'dispatched'
                              ? Colors.blue
                              : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Incident header
                Row(
                  children: [
                    Text(
                      _getCategoryIcon(incident.category),
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.category,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _getSeverityColor(incident.severity),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${incident.severity} Severity',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Location information
                _buildSectionCard(
                  context,
                  title: 'Location',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              incident.location,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Latitude',
                                  style: textTheme.bodySmall,
                                ),
                                Text(
                                  incident.latitude.toStringAsFixed(5),
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Longitude',
                                  style: textTheme.bodySmall,
                                ),
                                Text(
                                  incident.longitude.toStringAsFixed(5),
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                _buildSectionCard(
                  context,
                  title: 'Description',
                  child: Text(
                    incident.description,
                    style: textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),

                // Media attachments
                if (incident.mediaUrls != null && incident.mediaUrls!.isNotEmpty)
                  _buildSectionCard(
                    context,
                    title: 'Attachments',
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: incident.mediaUrls!
                          .map(
                            (url) => Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 16),

                // Anonymous reporting badge
                if (incident.isAnonymous)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.privacy_tip_outlined,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Anonymous Report',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Status timeline
                FutureBuilder<IncidentStatusResponse>(
                  future: _statusFuture,
                  builder: (context, statusSnapshot) {
                    if (statusSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (statusSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Could not load status timeline',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    if (!statusSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final statusResponse = statusSnapshot.data!;
                    final updates = statusResponse.updates.map((update) {
                      return IncidentStatusUpdate(
                        status: update.status,
                        description: update.description,
                        timestamp: update.timestamp,
                        isCompleted: true,
                      );
                    }).toList();

                    return IncidentStatusTracker(
                      statusUpdates: updates,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.grey[50],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
