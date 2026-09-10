// Web implementation using dart:js to call the Web Audio API
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Plays a synthesised oscillator tone via the Web Audio API.
void evalWebAudio(double freq, int durMs, double vol) {
  try {
    js.context.callMethod('sentinelPlayTone', [freq, durMs, vol]);
  } catch (_) {}
}

/// Must be called after a user-gesture to unlock AudioContext on iOS/Chrome.
void unlockWebAudio() {
  try {
    js.context.callMethod('sentinelUnlockAudio', []);
  } catch (_) {}
}
