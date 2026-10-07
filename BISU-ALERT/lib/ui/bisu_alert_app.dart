import 'package:flutter/material.dart';

import '../data/auth/auth_controller.dart';
import '../data/auth/auth_scope.dart';
import '../navigation/auth_gate.dart';
import 'screens/shake_to_alert_listener.dart';
import 'theme/app_theme.dart';
import 'widgets/sos_alarm_banner.dart';

class BisuAlertApp extends StatefulWidget {
  const BisuAlertApp({super.key});

  @override
  State<BisuAlertApp> createState() => _BisuAlertAppState();
}

class _BisuAlertAppState extends State<BisuAlertApp> {
  final AuthController _authController = AuthController();

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _authController,
      child: MaterialApp(
        title: 'BISU-Alert',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        // Both of these must sit *inside* MaterialApp, not around it.
        // ShakeToAlertListener opens a dialog and shows a snackbar, which need a
        // Navigator and a ScaffoldMessenger above them; wrapping MaterialApp put
        // it above both, so the shake prompt could never actually open.
        // SosAlarmOverlay stacks the alarm banner over whichever tab is open.
        home: const ShakeToAlertListener(
          child: SosAlarmOverlay(child: AuthGate()),
        ),
      ),
    );
  }
}
