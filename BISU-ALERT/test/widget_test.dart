import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bisu_alert_flutter/ui/bisu_alert_app.dart';

void main() {
  testWidgets('App smoke test initializes BisuAlertApp', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BisuAlertApp());
    await tester.pumpAndSettle();

    expect(find.byType(BisuAlertApp), findsOneWidget);
  });
}

