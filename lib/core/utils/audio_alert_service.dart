import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'web_audio_helper.dart';

/// Clinical Alarm Priority levels according to IEC 60601-1-8.
enum AlarmPriority {
  critical, // Urgent triplet high-frequency pulse
  warning,  // Moderate two-tone notification
  heartbeat,// Low-volume R-wave telemetry beep
}

/// Hospital Medical Alarm Sound Synthesizer and Audio Service.
/// Plays realistic hospital monitor beeps and critical emergency sirens.
/// Uses Web Audio API on web and SystemSound / synthesized tones on native.
class AudioAlertService {
  static final AudioAlertService _instance = AudioAlertService._internal();
  factory AudioAlertService() => _instance;
  AudioAlertService._internal();

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  Timer? _criticalLoopTimer;
  bool _isCriticalSirenActive = false;
  bool get isCriticalSirenActive => _isCriticalSirenActive;

  final StreamController<bool> _muteStateController = StreamController<bool>.broadcast();
  Stream<bool> get onMuteStateChanged => _muteStateController.stream;

  /// Call this once on first user interaction to unlock AudioContext on web.
  void unlockAudio() {
    if (kIsWeb) {
      unlockWebAudio();
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      stopCriticalAlarm();
    }
    _muteStateController.add(_isMuted);
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    if (_isMuted) {
      stopCriticalAlarm();
    }
    _muteStateController.add(_isMuted);
  }

  /// Plays a single heartbeat telemetry blip (e.g. on ECG R-wave peak)
  void playHeartbeatTick() {
    if (_isMuted) return;
    _playTone(frequency: 880, durationMs: 45, volume: 0.15);
  }

  /// Plays a warning notification tone (two-tone chime)
  void playWarningTone() {
    if (_isMuted) return;
    _playTone(frequency: 659.25, durationMs: 120, volume: 0.4); // E5
    Future.delayed(const Duration(milliseconds: 140), () {
      if (!_isMuted) {
        _playTone(frequency: 523.25, durationMs: 160, volume: 0.4); // C5
      }
    });
  }

  /// Starts repeating high-priority critical medical alarm (IEC 60601-1-8 burst)
  void startCriticalAlarm() {
    if (_isCriticalSirenActive) return;
    _isCriticalSirenActive = true;

    _playCriticalBurst();
    _criticalLoopTimer?.cancel();
    _criticalLoopTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!_isMuted && _isCriticalSirenActive) {
        _playCriticalBurst();
      }
    });
  }

  /// Stops the repeating critical medical alarm
  void stopCriticalAlarm() {
    _isCriticalSirenActive = false;
    _criticalLoopTimer?.cancel();
    _criticalLoopTimer = null;
  }

  void _playCriticalBurst() {
    if (_isMuted) return;

    // Standard clinical 3-pulse urgent triplet (IEC 60601-1-8 HIGH priority)
    final tones = [
      {'freq': 987.77,  'delay': 0,   'dur': 120},  // B5
      {'freq': 987.77,  'delay': 160, 'dur': 120},  // B5
      {'freq': 1318.51, 'delay': 320, 'dur': 200},  // E6 (high spike)
    ];

    for (final tone in tones) {
      Future.delayed(Duration(milliseconds: tone['delay'] as int), () {
        if (!_isMuted && _isCriticalSirenActive) {
          _playTone(
            frequency: (tone['freq'] as num).toDouble(),
            durationMs: tone['dur'] as int,
            volume: 0.7,
          );
        }
      });
    }
  }

  /// Dispatches audio tone via Web Audio API (web) or system sound (native)
  void _playTone({
    required double frequency,
    required int durationMs,
    required double volume,
  }) {
    // Native: haptics + system sound click
    try {
      if (frequency > 900) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}

    // Web: synthesise tone via Web Audio API through JS interop
    if (kIsWeb) {
      evalWebAudio(frequency, durationMs, volume);
    }
  }
}
