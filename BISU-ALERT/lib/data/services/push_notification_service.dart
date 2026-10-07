import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler.
///
/// This MUST be a top-level function (not a class method): Firebase spawns a
/// separate isolate for background messages and looks the handler up by name.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The background isolate does not share state with main(), so Firebase has to
  // be initialized again here before touching any Firebase API.
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('Handling background message: ${message.messageId}');
  }
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Null until [initialize] completes with a working Firebase app. Every
  /// Firebase-backed method below no-ops while this is null, so the app still
  /// runs on a device with no `google-services.json` / `firebase_options.dart`.
  FirebaseMessaging? _firebaseMessaging;

  /// Whether push notifications (Firebase) are available on this build.
  bool get isPushAvailable => _firebaseMessaging != null;

  /// True once local (on-device) notifications are ready.
  bool _localReady = false;
  bool get isLocalNotificationAvailable => _localReady;

  /// Initialize local notifications, then Firebase Messaging.
  ///
  /// The two halves are initialized independently: if Firebase is not
  /// configured, local notifications still work and the app still starts.
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );
      _localReady = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing local notifications: $e');
      }
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Firebase.initializeApp() is done in main() before this runs. If it
      // failed (missing config), Firebase.apps is empty and there is no point
      // continuing -- bail out instead of throwing on every messaging call.
      if (Firebase.apps.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            'Push notifications disabled: Firebase is not configured. '
            'Add android/app/google-services.json (see FIREBASE_SETUP.md) '
            'to enable remote alerts.',
          );
        }
        return;
      }

      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      // Register the background handler before listening for foreground ones.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationMessage);

      // App launched from a terminated state by tapping a notification.
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        await _handleNotificationMessage(initialMessage);
      }

      _firebaseMessaging = messaging;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing push notifications: $e');
      }
    }
  }

  /// Get FCM token for this device, or null when push is unavailable.
  Future<String?> getToken() async {
    final messaging = _firebaseMessaging;
    if (messaging == null) return null;
    try {
      return await messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Show local notification (for foreground messages)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (!_localReady) return;
    try {
      // NOTE: a custom siren would go here as
      //   sound: RawResourceAndroidNotificationSound('alert_siren'),
      // but that requires android/app/src/main/res/raw/alert_siren.mp3 to
      // exist. Referencing a missing raw resource makes Android drop the
      // notification entirely, so we use the device's default alert sound
      // until that asset is added.
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'critical_alerts',
        'Critical Alerts',
        channelDescription: 'Critical emergency and safety alerts',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'BISU-Alert',
        message.notification?.body ?? 'Emergency alert received',
        notificationDetails,
        payload: message.data.toString(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error showing local notification: $e');
      }
    }
  }

  /// Handle messages received in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('Handling foreground message: ${message.messageId}');
    }

    // Android does not display FCM notifications while the app is in the
    // foreground, so surface it as a local notification instead.
    await _showLocalNotification(message);
  }

  /// Handle when user taps on a notification
  void _handleNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('User tapped notification with payload: ${response.payload}');
    }
    // Navigate to relevant screen based on payload
  }

  /// Handle message when app is opened from notification
  Future<void> _handleNotificationMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('App opened from notification: ${message.messageId}');
    }
    // Handle navigation based on message data
  }

  /// Subscribe to a topic for group notifications
  Future<void> subscribeToTopic(String topic) async {
    final messaging = _firebaseMessaging;
    if (messaging == null) return;
    try {
      await messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        debugPrint('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    final messaging = _firebaseMessaging;
    if (messaging == null) return;
    try {
      await messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        debugPrint('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error unsubscribing from topic: $e');
      }
    }
  }
}
