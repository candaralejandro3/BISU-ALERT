import 'package:bisu_alert_flutter/data/services/sos_alarm_service.dart';
import 'package:bisu_alert_flutter/ui/theme/app_theme.dart';
import 'package:bisu_alert_flutter/ui/widgets/sos_alarm_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Same viewports as layout_overflow_test.dart. The banner packs an icon, two
/// lines of text and a button into one row, so the 320px case is the one that
/// matters.
const Map<String, Size> _viewports = <String, Size>{
  'small phone': Size(320, 640),
  'typical phone': Size(392, 830),
  'large phone': Size(430, 932),
};

Widget _wrap() {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: const SosAlarmOverlay(
      child: Scaffold(body: Center(child: Text('screen'))),
    ),
  );
}

/// Raise the alarm without going through [SosAlarmService.start], which would
/// reach for the audio plugin that is not registered under `flutter test`.
void _activate({int seconds = 30}) {
  SosAlarmService().isActive.value = true;
  SosAlarmService().secondsRemaining.value = seconds;
}

void main() {
  // The overlay reads a singleton, so an alarm left active would leak into
  // whichever test ran next.
  tearDown(() {
    SosAlarmService().isActive.value = false;
    SosAlarmService().secondsRemaining.value = 0;
  });

  testWidgets('stays out of the way while no alarm is active',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('SOS ALARM ACTIVE'), findsNothing);
    expect(find.text('screen'), findsOneWidget);
  });

  testWidgets('shows the banner and countdown once the alarm is active',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap());

    _activate();
    await tester.pump();

    expect(find.text('SOS ALARM ACTIVE'), findsOneWidget);
    expect(find.text('Alert sent - silences in 0:30'), findsOneWidget);
  });

  testWidgets('countdown renders seconds zero-padded',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap());

    _activate(seconds: 7);
    await tester.pump();

    expect(find.text('Alert sent - silences in 0:07'), findsOneWidget);
  });

  testWidgets('STOP silences the alarm and dismisses the banner',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap());

    _activate();
    await tester.pump();

    await tester.tap(find.text('STOP'));
    await tester.pump();

    expect(SosAlarmService().isActive.value, isFalse);
    expect(find.text('SOS ALARM ACTIVE'), findsNothing);
  });

  for (final MapEntry<String, Size> viewport in _viewports.entries) {
    testWidgets('active banner lays out without overflow on ${viewport.key}',
        (WidgetTester tester) async {
      tester.view.physicalSize = viewport.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap());
      _activate();
      await tester.pump();

      // A RenderFlex overflow surfaces as a FlutterError the binding records
      // rather than throws.
      expect(
        tester.takeException(),
        isNull,
        reason: 'alarm banner overflowed at ${viewport.key} '
            '(${viewport.value.width}x${viewport.value.height})',
      );
    });
  }
}
