import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth/auth_scope.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/register_screen.dart';
import '../ui/screens/onboarding_screen.dart';
import 'main_shell.dart';

enum _AuthPage { login, register }

/// Decides what the app shows: the onboarding tutorial for first-time users,
/// sign-in / registration when there is no session, and the tabbed shell
/// once a user is signed in.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  _AuthPage _page = _AuthPage.login;
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool seen = prefs.getBool(OnboardingScreen.prefKey) ?? false;
      if (mounted) {
        setState(() => _hasSeenOnboarding = seen);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasSeenOnboarding = true);
      }
    }
  }

  void _show(_AuthPage page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenOnboarding == false) {
      return OnboardingScreen(
        onGetStarted: () {
          setState(() => _hasSeenOnboarding = true);
        },
      );
    }

    if (AuthScope.of(context).isSignedIn) {
      return const MainShell();
    }

    return switch (_page) {
      _AuthPage.login => LoginScreen(
          onCreateAccount: () => _show(_AuthPage.register),
        ),
      _AuthPage.register => RegisterScreen(
          onBackToLogin: () => _show(_AuthPage.login),
          onRegistered: () => _show(_AuthPage.login),
        ),
    };
  }
}

