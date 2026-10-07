import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The BISU-Alert mark, drawn from a single asset so the dashboard header, the
/// auth screens, and the launcher icon never drift apart.
///
/// The artwork is a circular badge, so it is clipped to an oval and can be
/// dropped onto any background. If the asset is missing the widget degrades to
/// the shield placeholder instead of throwing.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 52,
    this.opacity = 1,
    this.hasShadow = false,
  });

  /// Every logo surface in the app resolves to this file.
  static const String assetPath = 'assets/images/BISU-ALERT.png';

  /// Width and height of the badge in logical pixels.
  final double size;

  /// Used by the auth backdrop to fade the mark into a watermark.
  final double opacity;

  /// Lifts the badge off coloured or gradient backgrounds.
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    Widget badge = ClipOval(
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        opacity: AlwaysStoppedAnimation<double>(opacity),
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
          return _MissingLogoFallback(size: size, opacity: opacity);
        },
      ),
    );

    if (hasShadow) {
      badge = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: size * 0.22,
              offset: Offset(0, size * 0.06),
            ),
          ],
        ),
        child: badge,
      );
    }

    return SizedBox(width: size, height: size, child: badge);
  }
}

/// Shown until `assets/images/bisu_alert_logo.png` is added, so a missing file
/// never breaks a screen.
class _MissingLogoFallback extends StatelessWidget {
  const _MissingLogoFallback({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.shield_outlined,
          color: Colors.white,
          size: size * 0.54,
        ),
      ),
    );
  }
}
