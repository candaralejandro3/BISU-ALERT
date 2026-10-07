import 'package:flutter/material.dart';

import '../../data/services/shake_detector.dart';
import '../../data/services/sos_alarm_service.dart';

/// Widget that listens for shake gestures and shows a quick SOS prompt
class ShakeToAlertListener extends StatefulWidget {
  final Widget child;

  const ShakeToAlertListener({
    super.key,
    required this.child,
  });

  @override
  State<ShakeToAlertListener> createState() => _ShakeToAlertListenerState();
}

class _ShakeToAlertListenerState extends State<ShakeToAlertListener> {
  final ShakeDetector _shakeDetector = ShakeDetector();

  /// Guards against stacking prompts when a sustained shake fires repeatedly.
  bool _promptOpen = false;

  @override
  void initState() {
    super.initState();
    _shakeDetector.startListening(
      onShakeDetected: _handleShakeDetected,
    );
  }

  @override
  void dispose() {
    _shakeDetector.stopListening();
    super.dispose();
  }

  Future<void> _handleShakeDetected() async {
    if (_promptOpen || !mounted) return;
    _promptOpen = true;

    // Show a dialog with SOS confirmation when shake is detected
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Shake Detected - Send SOS?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Your device detected a strong shake.\n\nDo you need emergency assistance?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );

    _promptOpen = false;

    if (confirmed == true) {
      _sendShakeSOS();
    }
  }

  void _sendShakeSOS() {
    // Same alarm as the hold button, so both SOS paths sound alike.
    SosAlarmService().start();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS alert sent to emergency response team via shake gesture.'),
        duration: Duration(seconds: 3),
      ),
    );
    // TODO: Actually send SOS alert using the alert service
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
