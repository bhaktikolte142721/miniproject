import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_incident.dart';
import '../core/utils/audio_alert_service.dart';
import 'telemetry_provider.dart';
import 'telemetry_mode_provider.dart';

/// Real-time stream of clinical alert incidents with live countdowns
final alertsStreamProvider = StreamProvider<List<AlertIncident>>((ref) {
  final modeState = ref.watch(telemetryModeProvider);

  if (modeState.isSimulation) {
    final mockService = ref.watch(mockTelemetryServiceProvider);
    return mockService.alertsStream;
  }

  // Live Mode: Consume critical alarms from Node.js backend
  final socketService = ref.watch(socketServiceProvider);

  return socketService.onCriticalAlarm.map((list) {
    return list.map((json) => AlertIncident.fromJson(json)).toList();
  });
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
  final modeState = ref.watch(telemetryModeProvider);

  if (modeState.isSimulation) {
    final mockService = ref.watch(mockTelemetryServiceProvider);
    return mockService.resolvedAlarmsStream;
  }

  // Live Mode: Consume alarm stats from server
  final socketService = ref.watch(socketServiceProvider);
  return socketService.onAlarmStats.map((stats) {
    return (stats['resolvedAlarmsCount'] as num?)?.toInt() ?? 0;
  });
});

/// Unified action to acknowledge an active alarm on either live backend or mock service
void acknowledgeAlertAction(WidgetRef ref, String alertId, String nurseName) {
  final modeState = ref.read(telemetryModeProvider);
  if (modeState.isLive) {
    ref.read(socketServiceProvider).acknowledgeAlarm(alertId, nurseName);
  } else {
    ref.read(mockTelemetryServiceProvider).acknowledgeAlert(alertId, nurseName);
  }
}

/// Unified action to clear/resolve an active alarm on either live backend or mock service
void clearAlertAction(WidgetRef ref, String? alertId) {
  final modeState = ref.read(telemetryModeProvider);
  if (modeState.isLive) {
    ref.read(socketServiceProvider).clearAlarm(alertId);
  } else {
    ref.read(mockTelemetryServiceProvider).clearAlert(alertId ?? '');
  }
}
