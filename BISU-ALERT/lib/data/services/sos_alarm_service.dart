import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sounds the looping SOS siren and tracks whether it is going.
///
/// A completed SOS is meant to be heard: the siren is loud, loops, and routes
/// itself as an *alarm* so a silenced ringer does not suppress it. It stops on
/// [stop] -- the banner's STOP button -- or on its own after [maxDuration], so
/// a forgotten alarm does not wail indefinitely.
///
/// Singleton because the siren is a device-wide condition: the hold button and
/// the shake gesture must talk to one player, or a second trigger would layer a
/// second siren over the first.
class SosAlarmService {
  static final SosAlarmService _instance = SosAlarmService._internal();

  factory SosAlarmService() {
    return _instance;
  }

  SosAlarmService._internal();

  /// How long the siren runs before silencing itself.
  static const Duration maxDuration = Duration(seconds: 30);

  /// Siren path *relative to [AssetSource]'s built-in `assets/` prefix*, so
  /// this resolves to `assets/sounds/sos_siren.wav`. Regenerate that file with
  /// `python tools/generate_siren.py`.
  static const String _sirenAsset = 'sounds/sos_siren.wav';

  /// Treat the siren as an alarm rather than media.
  ///
  /// On Android the `alarm` usage keeps it off the music stream, so it is not
  /// ducked by other audio and still sounds when the ringer is silenced.
  /// `gainTransient` is Android's documented focus type for a finite alarm:
  /// whatever the user was listening to resumes once the siren stops. On iOS
  /// the `playback` category is the one that ignores the Ring/Silent switch.
  static final AudioContext _alarmContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.gainTransient,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
    ),
  );

  /// Built on first [start], never in the constructor. Constructing an
  /// [AudioPlayer] reaches for the platform plugin, which is not registered
  /// under `flutter test` -- doing it eagerly would make merely building a
  /// widget that references this singleton throw.
  AudioPlayer? _player;

  Timer? _autoStopTimer;
  Timer? _tickTimer;

  /// Whether the siren is sounding. Drives the alarm banner.
  final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);

  /// Seconds left before the auto-stop fires, for the banner's countdown.
  final ValueNotifier<int> secondsRemaining = ValueNotifier<int>(0);

  /// Start the siren.
  ///
  /// A no-op while it is already sounding, so a sustained shake or a
  /// double-tapped SOS cannot stack two sirens or restart the countdown.
  Future<void> start() async {
    if (isActive.value) return;

    isActive.value = true;
    secondsRemaining.value = maxDuration.inSeconds;
    _startTimers();

    try {
      final AudioPlayer player = _player ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(
        AssetSource(_sirenAsset),
        volume: 1.0,
        ctx: _alarmContext,
      );
    } catch (e) {
      // Audio is the loudest part of the alarm but not the only part: the
      // banner and the haptic buzz already fired, so leave the alarm state up
      // rather than pretending nothing happened.
      if (kDebugMode) {
        debugPrint('SOS siren could not start: $e');
      }
    }
  }

  /// Silence the siren and clear the banner.
  Future<void> stop() async {
    _tickTimer?.cancel();
    _tickTimer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    isActive.value = false;
    secondsRemaining.value = 0;

    try {
      await _player?.stop();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SOS siren could not stop: $e');
      }
    }
  }

  void _startTimers() {
    _tickTimer?.cancel();
    _autoStopTimer?.cancel();

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final int next = secondsRemaining.value - 1;
      secondsRemaining.value = next < 0 ? 0 : next;
    });

    _autoStopTimer = Timer(maxDuration, stop);
  }
}
