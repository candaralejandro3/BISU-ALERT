import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/sos_alarm_service.dart';
import '../theme/app_colors.dart';

/// Instant-tap emergency SOS button.
///
/// Tapping this button immediately sounds the school emergency alarm, provides
/// haptic feedback, and invokes [onCompleted]. When the alarm is actively
/// sounding, the button pulses and allows tapping to silence the alarm.
class SosHoldButton extends StatefulWidget {
  const SosHoldButton({
    super.key,
    required this.onCompleted,
    this.holdDurationSeconds = 0,
  });

  final VoidCallback onCompleted;

  /// Retained for backwards compatibility with existing calls.
  final int holdDurationSeconds;

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

/// Convenience alias for clarity.
typedef SosTapButton = SosHoldButton;

class _SosHoldButtonState extends State<SosHoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // If alarm is already active on mount, start pulsing immediately.
    if (SosAlarmService().isActive.value) {
      _pulseController.repeat(reverse: true);
    }

    SosAlarmService().isActive.addListener(_onAlarmStateChanged);
  }

  void _onAlarmStateChanged() {
    if (!mounted) return;
    if (SosAlarmService().isActive.value) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
    setState(() {});
  }

  @override
  void dispose() {
    SosAlarmService().isActive.removeListener(_onAlarmStateChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.heavyImpact();

    if (SosAlarmService().isActive.value) {
      // If already sounding, tapping silences it.
      SosAlarmService().stop();
    } else {
      // Tap immediately sounds the alarm and notifies callbacks.
      SosAlarmService().start();
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SosAlarmService().isActive,
      builder: (BuildContext context, bool isAlarmActive, Widget? _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _handleTap();
              },
              onTapCancel: () => setState(() => _isPressed = false),
              child: AnimatedScale(
                scale: _isPressed ? 0.94 : 1.0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: 210,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer animated aura / pulse ring
                      if (isAlarmActive)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 210 * _pulseAnimation.value,
                              height: 210 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.sos.withValues(
                                  alpha: (0.35 * (1.2 - _pulseAnimation.value + 0.8))
                                      .clamp(0.05, 0.35),
                                ),
                              ),
                            );
                          },
                        ),
                      // Static ambient ring
                      Container(
                        width: 204,
                        height: 204,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isAlarmActive
                                ? AppColors.sos
                                : AppColors.sos.withValues(alpha: 0.30),
                            width: 3,
                          ),
                        ),
                      ),
                      // Main SOS tap button
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          color: isAlarmActive
                              ? const Color(0xFFC62828)
                              : AppColors.sos,
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-0.2, -0.3),
                            radius: 0.9,
                            colors: isAlarmActive
                                ? [
                                    const Color(0xFFFF5252),
                                    const Color(0xFFB71C1C),
                                  ]
                                : [
                                    const Color(0xFFE53935),
                                    const Color(0xFFC62828),
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sos.withValues(
                                alpha: isAlarmActive ? 0.65 : 0.40,
                              ),
                              blurRadius: isAlarmActive ? 24 : 16,
                              spreadRadius: isAlarmActive ? 4 : 2,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isAlarmActive
                                  ? Icons.volume_up_rounded
                                  : Icons.touch_app_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAlarmActive ? 'ALARM' : 'TAP',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                letterSpacing: 1.2,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              isAlarmActive ? 'ACTIVE' : 'FOR SOS',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 0.8,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isAlarmActive
                  ? 'Tap button to stop alarm'
                  : 'Tap to sound alarm immediately',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isAlarmActive
                        ? AppColors.sos
                        : AppColors.sos.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        );
      },
    );
  }
}