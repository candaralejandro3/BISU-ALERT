import 'package:bisu_alert_flutter/data/auth/auth_controller.dart';
import 'package:bisu_alert_flutter/data/auth/auth_scope.dart';
import 'package:bisu_alert_flutter/ui/screens/auth/login_screen.dart';
import 'package:bisu_alert_flutter/ui/screens/auth/register_screen.dart';
import 'package:bisu_alert_flutter/ui/screens/emergency_contacts_screen.dart';
import 'package:bisu_alert_flutter/ui/screens/emergency_directory_screen.dart';
import 'package:bisu_alert_flutter/ui/screens/home_screen.dart';
import 'package:bisu_alert_flutter/ui/screens/map_screen.dart';
import 'package:bisu_alert_flutter/ui/screens/profile_settings_screen.dart';
import 'package:bisu_alert_flutter/ui/screens/report_incident_screen.dart';
import 'package:bisu_alert_flutter/ui/screens/user_profile_screen.dart';
import 'package:bisu_alert_flutter/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Viewports the app is expected to look correct on. The narrow/short one
/// approximates a small budget Android phone, which is what surfaced the
/// original RenderFlex overflows on the Quick Actions grid.
const Map<String, Size> _viewports = <String, Size>{
  'small phone': Size(320, 640),
  'typical phone': Size(392, 830),
  'large phone': Size(430, 932),
};

/// Screens that can be constructed with no external state.
Map<String, Widget> _screens() => <String, Widget>{
      'HomeScreen': const HomeScreen(),
      'MapScreen': const MapScreen(),
      'EmergencyDirectoryScreen': const EmergencyDirectoryScreen(),
      'EmergencyContactsScreen': const EmergencyContactsScreen(),
      'ReportIncidentScreen': const ReportIncidentScreen(),
      'UserProfileScreen': const UserProfileScreen(),
      'ProfileSettingsScreen': const ProfileSettingsScreen(),
      'LoginScreen': LoginScreen(onCreateAccount: () {}),
      'RegisterScreen': RegisterScreen(
        onBackToLogin: () {},
        onRegistered: () {},
      ),
    };

Widget _wrap(Widget screen, AuthController controller) {
  return AuthScope(
    controller: controller,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: screen),
    ),
  );
}

void main() {
  for (final MapEntry<String, Size> viewport in _viewports.entries) {
    group('lays out without overflow on ${viewport.key}', () {
      for (final MapEntry<String, Widget> entry in _screens().entries) {
        testWidgets(entry.key, (WidgetTester tester) async {
          tester.view.physicalSize = viewport.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final AuthController controller = AuthController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(_wrap(entry.value, controller));
          await tester.pump(const Duration(milliseconds: 100));

          // A RenderFlex overflow is reported as a FlutterError during layout,
          // which the test binding records rather than throwing.
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} overflowed at ${viewport.key} '
                '(${viewport.value.width}x${viewport.value.height})',
          );
        });
      }
    });
  }
}
