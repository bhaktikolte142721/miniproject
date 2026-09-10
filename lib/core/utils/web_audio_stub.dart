// Stub for non-web platforms (mobile, desktop)
void evalWebAudio(double freq, int durMs, double vol) {
  // No-op on native platforms — audio handled via HapticFeedback/SystemSound
}

void unlockWebAudio() {
  // No-op on native
}
