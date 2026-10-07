import 'package:flutter/material.dart';

import '../../data/services/connectivity_status_service.dart';

/// Widget to display connectivity status
class ConnectivityStatusWidget extends StatefulWidget {
  final ConnectivityStatusService? service;

  const ConnectivityStatusWidget({
    super.key,
    this.service,
  });

  @override
  State<ConnectivityStatusWidget> createState() =>
      _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget> {
  late ConnectivityStatusService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ConnectivityStatusService();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: _service.statusStream,
      initialData: _service.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectivityStatus.unknown;

        if (status == ConnectivityStatus.online) {
          // Don't show anything when online
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: status == ConnectivityStatus.offline
              ? Colors.red.shade600
              : Colors.orange.shade600,
          child: Row(
            children: [
              Icon(
                _service.getStatusIcon(),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  status == ConnectivityStatus.offline
                      ? 'You are offline. Some features may be limited.'
                      : 'Connection status unknown',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Floating status indicator
class FloatingConnectivityStatus extends StatefulWidget {
  final ConnectivityStatusService? service;

  const FloatingConnectivityStatus({
    super.key,
    this.service,
  });

  @override
  State<FloatingConnectivityStatus> createState() =>
      _FloatingConnectivityStatusState();
}

class _FloatingConnectivityStatusState extends State<FloatingConnectivityStatus> {
  late ConnectivityStatusService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ConnectivityStatusService();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: _service.statusStream,
      initialData: _service.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectivityStatus.unknown;

        if (status == ConnectivityStatus.online) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 16,
          right: 16,
          child: Material(
            borderRadius: BorderRadius.circular(12),
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: status == ConnectivityStatus.offline
                    ? Colors.red.shade600
                    : Colors.orange.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _service.getStatusIcon(),
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _service.getStatusText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
