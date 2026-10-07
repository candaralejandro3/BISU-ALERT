import 'package:flutter/material.dart';

/// Model for an incident status update
class IncidentStatusUpdate {
  final String status;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;

  IncidentStatusUpdate({
    required this.status,
    required this.description,
    required this.timestamp,
    this.isCompleted = false,
  });
}

/// Widget to display live incident status tracking
class IncidentStatusTracker extends StatelessWidget {
  final List<IncidentStatusUpdate> statusUpdates;

  const IncidentStatusTracker({
    super.key,
    required this.statusUpdates,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Status Timeline',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TimelineWidget(
          events: statusUpdates.map((update) {
            return TimelineEvent(
              title: update.status,
              description: update.description,
              time: _formatTime(update.timestamp),
              isCompleted: update.isCompleted,
              color: update.isCompleted ? colorScheme.primary : Colors.grey,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Single timeline event
class TimelineEvent {
  final String title;
  final String description;
  final String time;
  final bool isCompleted;
  final Color color;

  TimelineEvent({
    required this.title,
    required this.description,
    required this.time,
    required this.isCompleted,
    required this.color,
  });
}

/// Timeline widget
class TimelineWidget extends StatelessWidget {
  final List<TimelineEvent> events;

  const TimelineWidget({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;

        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line and dot
              Column(
                children: [
                  // Dot
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: event.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: event.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: event.isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  // Line to next event
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 60,
                      color: event.color.withValues(alpha: 0.3),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: event.color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.time,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
