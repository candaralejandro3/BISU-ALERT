import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

/// First-launch onboarding and tutorial screen.
/// Introduces students, faculty, and visitors to the core safety tools
/// before an emergency happens.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.onGetStarted,
    this.isReplay = false,
  });

  final VoidCallback onGetStarted;
  final bool isReplay;

  static const String prefKey = 'bisu_alert_has_seen_onboarding';

  Future<void> _completeOnboarding(BuildContext context) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, true);
    } catch (_) {}
    onGetStarted();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isReplay
          ? AppBar(
              title: const Text('App Tutorial'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    // University / App Emergency Shield Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'WELCOME TO BISU-ALERT',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bohol Island State University • Bilar Campus',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Feature 1: Emergency SOS
                    const _FeatureTutorialCard(
                      iconEmoji: '🚨',
                      title: 'Emergency SOS',
                      description: 'Quickly request emergency assistance.',
                      highlightColor: Color(0xFFEF4444),
                      accentBg: Color(0xFFFEF2F2),
                    ),
                    const SizedBox(height: 14),

                    // Feature 2: Campus Map
                    const _FeatureTutorialCard(
                      iconEmoji: '🗺️',
                      title: 'Campus Map',
                      description: 'Find buildings, emergency hubs and safe zones.',
                      highlightColor: Color(0xFF10B981),
                      accentBg: Color(0xFFECFDF5),
                    ),
                    const SizedBox(height: 14),

                    // Feature 3: Alerts
                    const _FeatureTutorialCard(
                      iconEmoji: '📢',
                      title: 'Alerts',
                      description: 'Receive important campus announcements.',
                      highlightColor: Color(0xFFF59E0B),
                      accentBg: Color(0xFFFFFBEB),
                    ),
                    const SizedBox(height: 14),

                    // Feature 4: Emergency Directory
                    const _FeatureTutorialCard(
                      iconEmoji: '☎️',
                      title: 'Emergency Directory',
                      description: 'Contact campus responders quickly.',
                      highlightColor: Color(0xFF3B82F6),
                      accentBg: Color(0xFFEFF6FF),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Action Area
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (isReplay) {
                      Navigator.of(context).pop();
                    } else {
                      _completeOnboarding(context);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    isReplay ? 'Back to App' : 'Get Started',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTutorialCard extends StatelessWidget {
  const _FeatureTutorialCard({
    required this.iconEmoji,
    required this.title,
    required this.description,
    required this.highlightColor,
    required this.accentBg,
  });

  final String iconEmoji;
  final String title;
  final String description;
  final Color highlightColor;
  final Color accentBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: highlightColor.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Text(
              iconEmoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
