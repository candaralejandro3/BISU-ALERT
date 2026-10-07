import 'package:flutter/material.dart';

import '../../data/services/sos_alarm_service.dart';
import '../theme/app_colors.dart';

/// Stacks the SOS alarm banner above the whole app.
///
/// The alarm can be raised from the home screen's hold button *or* from a shake
/// on any tab, so the stop control cannot live on a single screen. Wrapping the
/// navigator's first route keeps one banner reachable from everywhere.
///
/// The banner is pinned to the top on purpose: the bottom of the screen belongs
/// to [MainShell]'s navigation bar, and covering that would trap the user.
class SosAlarmOverlay extends StatelessWidget {
  const SosAlarmOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: SosAlarmService().isActive,
            builder: (BuildContext context, bool isActive, Widget? _) {
              if (!isActive) {
                return const SizedBox.shrink();
              }
              return const _AlarmBanner();
            },
          ),
        ),
      ],
    );
  }
}

class _AlarmBanner extends StatelessWidget {
  const _AlarmBanner();

  /// `m:ss`, so a 30 second alarm reads as `0:30`.
  static String _countdown(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sos,
      elevation: 8,
      child: SafeArea(
        // Only the top inset matters: the banner never reaches the bottom edge.
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 12),
              // Expanded + single-line ellipsis: this row carries a button and
              // a countdown, and must survive a narrow screen or a large font
              // scale without overflowing.
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SOS ALARM ACTIVE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ValueListenableBuilder<int>(
                      valueListenable: SosAlarmService().secondsRemaining,
                      builder:
                          (BuildContext context, int seconds, Widget? _) {
                        return Text(
                          'Alert sent - silences in ${_countdown(seconds)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: SosAlarmService().stop,
                icon: const Icon(Icons.stop_rounded, size: 20),
                label: const Text('STOP'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.sos,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
