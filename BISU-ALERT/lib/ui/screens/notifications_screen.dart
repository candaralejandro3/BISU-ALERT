import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum NotificationType { critical, weather, resolved, general }

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'all';

  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: '🔴 Critical Emergency Dispatch',
      body: 'Medical assistance requested at Student Center / Gymnasium. Security personnel dispatched.',
      type: NotificationType.critical,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: '🟡 Weather Alert - Heavy Rainfall',
      body: 'Heavy rainfall advisory around campus grounds. Exercise caution along unpaved walkways.',
      type: NotificationType.weather,
      timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: '🟢 Incident Resolved',
      body: 'Your reported incident INC-002 (Facility damage at CEA) has been resolved by maintenance.',
      type: NotificationType.resolved,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: '📢 Safety Announcement',
      body: 'Quarterly campus-wide evacuation drill scheduled for tomorrow at 9:00 AM at Assembly Area A.',
      type: NotificationType.general,
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      isRead: true,
    ),
  ];

  List<NotificationItem> get _filtered {
    if (_selectedFilter == 'critical') {
      return _notifications.where((n) => n.type == NotificationType.critical).toList();
    } else if (_selectedFilter == 'weather') {
      return _notifications.where((n) => n.type == NotificationType.weather).toList();
    } else if (_selectedFilter == 'resolved') {
      return _notifications.where((n) => n.type == NotificationType.resolved).toList();
    }
    return _notifications;
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _chip('all', 'All (${_notifications.length})'),
                const SizedBox(width: 8),
                _chip('critical', '🔴 Critical'),
                const SizedBox(width: 8),
                _chip('weather', '🟡 Weather'),
                const SizedBox(width: 8),
                _chip('resolved', '🟢 Resolved'),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No notifications in this category.', style: TextStyle(color: Colors.black54)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _NotificationTile(
                        item: item,
                        onTap: () {
                          setState(() => item.isRead = true);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      onSelected: (_) => setState(() => _selectedFilter = key),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : Colors.black87,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  final NotificationItem item;
  final VoidCallback onTap;

  Color _accentColor() {
    switch (item.type) {
      case NotificationType.critical:
        return AppColors.sos;
      case NotificationType.weather:
        return const Color(0xFF0288D1);
      case NotificationType.resolved:
        return const Color(0xFF2E7D32);
      case NotificationType.general:
        return const Color(0xFFED6C02);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor();

    return Material(
      color: item.isRead ? Colors.white : color.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isRead ? Colors.black12 : color.withValues(alpha: 0.3),
              width: item.isRead ? 1 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w800,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (!item.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.body,
                style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35),
              ),
              const SizedBox(height: 8),
              Text(
                '${item.timestamp.hour % 12 == 0 ? 12 : item.timestamp.hour % 12}:${item.timestamp.minute.toString().padLeft(2, '0')} ${item.timestamp.hour >= 12 ? 'PM' : 'AM'}',
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
