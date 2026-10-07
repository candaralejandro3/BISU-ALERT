import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data/services/api_service.dart';
import 'data/services/push_notification_service.dart';
import 'ui/bisu_alert_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore custom campus backend URL if saved
  await ApiService().loadSavedBaseUrl();

  // Firebase must be initialized before any Firebase API is touched. It is
  // intentionally non-fatal: the app is an emergency tool and must still start
  // (SOS, offline SMS, map, directory) even when push config is missing.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) {
      debugPrint(
        'Firebase init failed -- remote push notifications will be disabled. '
        'Add android/app/google-services.json (see FIREBASE_SETUP.md). Error: $e',
      );
    }
  }

  // Safe to call regardless: it degrades to local-only notifications when
  // Firebase is unavailable.
  await PushNotificationService().initialize();

  runApp(const BisuAlertApp());
}
