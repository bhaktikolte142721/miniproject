import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_incident.dart';
import '../core/utils/audio_alert_service.dart';
import 'telemetry_provider.dart';

/// Real-time stream of clinical alert incidents with live countdowns
final alertsStreamProvider = StreamProvider<List<AlertIncident>>((ref) {
  final service = ref.watch(mockTelemetryServiceProvider);
  return service.alertsStream;
});

/// Count of active unacknowledged critical alarms
final activeCriticalAlarmsCountProvider = Provider<int>((ref) {
  final alertsAsync = ref.watch(alertsStreamProvider);
  return alertsAsync.maybeWhen(
    data: (alerts) => alerts
        .where((a) => a.severity == AlertSeverity.critical && !a.isAcknowledged)
        .length,
    orElse: () => 0,
  );
});

/// Total active alert count (critical + warning)
final totalActiveAlarmsCountProvider = Provider<int>((ref) {
  final alertsAsync = ref.watch(alertsStreamProvider);
  return alertsAsync.maybeWhen(
    data: (alerts) => alerts.where((a) => !a.isAcknowledged).length,
    orElse: () => 0,
  );
});

/// Audio Alert Service provider
final audioAlertServiceProvider = Provider<AudioAlertService>((ref) {
  return AudioAlertService();
});

/// Stream of audio mute state
final isAudioMutedStreamProvider = StreamProvider<bool>((ref) {
  final audioService = ref.watch(audioAlertServiceProvider);
  return audioService.onMuteStateChanged;
});

/// Count of clinical alarms successfully handled and resolved during this shift
final resolvedAlarmsCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(mockTelemetryServiceProvider);
  return service.resolvedAlarmsStream;
});

