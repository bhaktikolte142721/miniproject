import 'dart:js' as js;

void playToneWeb(double freq, int durMs, double vol) {
  try {
    js.context.callMethod('playSentinelAlarmTone', [freq, durMs, vol]);
  } catch (_) {}
}

void unlockAudioWeb() {
  try {
    js.context.callMethod('unlockSentinelAudio', []);
  } catch (_) {}
}
