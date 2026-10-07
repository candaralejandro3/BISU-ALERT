import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_logo.dart';

/// Shared chrome for the sign-in and registration screens: branded backdrop,
/// branded header, centred column, and a max width so the forms stay readable
/// on wide screens.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _AuthBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 26,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const AppLogo(size: 56, hasShadow: true),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: AppColors.sos,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).cardColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.warning_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BISU-Alert',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'BISU Bilar Campus Emergency Response',
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Text(
                        title,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(subtitle, style: textTheme.bodyMedium),
                      const SizedBox(height: 18),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-bleed background for the auth flow: a brand gradient that runs from the
/// BISU green through to the alert red, with an oversized seal watermark
/// bleeding off the top-right corner.
class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double markSize = MediaQuery.sizeOf(context).width * 1.15;

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const <Color>[
                    Color(0xFF0A1A10),
                    Color(0xFF141210),
                    Color(0xFF1C0E0E),
                  ]
                : <Color>[
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.background,
                    AppColors.sos.withValues(alpha: 0.10),
                  ],
          ),
        ),
        child: ClipRect(
          child: Stack(
            children: [
              Positioned(
                top: -markSize * 0.30,
                right: -markSize * 0.34,
                child: AppLogo(
                  size: markSize,
                  opacity: isDark ? 0.10 : 0.07,
                ),
              ),
              Positioned(
                bottom: -markSize * 0.24,
                left: -markSize * 0.28,
                child: AppLogo(
                  size: markSize * 0.7,
                  opacity: isDark ? 0.06 : 0.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary form action that swaps its label for a spinner while a request is in
/// flight, and disables itself so the form cannot be submitted twice.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: isBusy ? null : onPressed,
      child: isBusy
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

/// Inline banner for failed sign-in / registration attempts.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final Color error = Theme.of(context).colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: error)),
          ),
        ],
      ),
    );
  }
}
