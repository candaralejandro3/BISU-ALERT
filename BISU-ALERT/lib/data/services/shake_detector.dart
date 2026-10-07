import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

typedef ShakeCallback = void Function();

class ShakeDetector {
  static final ShakeDetector _instance = ShakeDetector._internal();

  factory ShakeDetector() {
    return _instance;
  }

  ShakeDetector._internal();

  StreamSubscription? _streamSubscription;
  ShakeCallback? onShake;

  /// Standard gravity in m/s^2. `accelerometerEvents` reports acceleration
  /// *including* gravity, so readings are normalised by this to get g-force.
  static const double _gravity = 9.80665;

  // Thresholds for shake detection, in multiples of gravity (g).
  // At rest the normalised magnitude is ~1.0g, so 2.7g requires a real shake.
  static const double _shakeThresholdGravity = 2.7;
  static const int _shakeSlopTimeMs = 500;
  static const int _shakeCountResetTime = 3000;

  int _shakeCount = 0;
  int _lastShakeTime = 0;

  /// Start listening for shake gestures
  void startListening({required ShakeCallback onShakeDetected}) {
    onShake = onShakeDetected;

    // Guard against double-subscribing: this is a singleton, and leaking a
    // second subscription would double-fire the SOS callback.
    _streamSubscription?.cancel();
    _shakeCount = 0;
    _lastShakeTime = 0;

    _streamSubscription = accelerometerEventStream().listen(
      _onAccelerometerEvent,
      onError: (error) {
        if (kDebugMode) {
          debugPrint('Accelerometer error: $error');
        }
      },
      // Keep listening after a transient sensor error -- cancelling would
      // silently disable shake-to-SOS for the rest of the session.
      cancelOnError: false,
    );
  }

  /// Stop listening for shake gestures
  void stopListening() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    onShake = null;
    _shakeCount = 0;
    _lastShakeTime = 0;
  }

  /// Handle accelerometer events
  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Normalise to g-force so gravity contributes ~1.0 at rest.
    final double gX = event.x / _gravity;
    final double gY = event.y / _gravity;
    final double gZ = event.z / _gravity;

    final double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

    // Check if g-force exceeds threshold (shake detected)
    if (gForce > _shakeThresholdGravity) {
      final int now = DateTime.now().millisecondsSinceEpoch;

      // Reset shake count if enough time has passed
      if (now - _lastShakeTime > _shakeCountResetTime) {
        _shakeCount = 0;
      }

      // Only count if enough time has passed since last shake
      if (now - _lastShakeTime > _shakeSlopTimeMs) {
        _shakeCount++;
        _lastShakeTime = now;

        // Trigger callback after significant shake is detected
        if (_shakeCount >= 2) {
          onShake?.call();
          _shakeCount = 0;
        }
      }
    }
  }
}
