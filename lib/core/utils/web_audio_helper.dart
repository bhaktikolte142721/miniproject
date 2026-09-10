/// Conditional export: uses Web Audio API on web, no-op stub elsewhere.
export 'web_audio_stub.dart'
    if (dart.library.js) 'web_audio_web.dart';
