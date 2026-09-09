import 'dart:async';
import 'dart:math' as math;
import '../models/patient.dart';
import '../models/telemetry_data.dart';
import '../models/node_status.dart';
import '../models/alert_incident.dart';
import '../core/utils/audio_alert_service.dart';

/// Autonomous physiological simulation service.
/// Generates realistic human vitals for Beds 1, 2, and 3, complete with
/// sinus arrhythmia, respiratory modulation, threshold evaluations, and chaos injection.
class MockTelemetryService {
  final math.Random _random = math.Random();
  Timer? _tickerTimer;
  Timer? _countdownTimer;

  // Stream Controllers
  final StreamController<Map<String, TelemetryData>> _telemetryController =
      StreamController<Map<String, TelemetryData>>.broadcast();
  final StreamController<Map<String, NodeStatus>> _nodesController =
      StreamController<Map<String, NodeStatus>>.broadcast();
  final StreamController<List<AlertIncident>> _alertsController =
      StreamController<List<AlertIncident>>.broadcast();
  final StreamController<GatewayStatus> _gatewayController =
      StreamController<GatewayStatus>.broadcast();

  Stream<Map<String, TelemetryData>> get telemetryStream => _telemetryController.stream;
  Stream<Map<String, NodeStatus>> get nodesStream => _nodesController.stream;
  Stream<List<AlertIncident>> get alertsStream => _alertsController.stream;
  Stream<GatewayStatus> get gatewayStream => _gatewayController.stream;

  // State cache
  final Map<String, TelemetryData> _currentTelemetry = {};
  final Map<String, NodeStatus> _currentNodes = {};
  final List<AlertIncident> _activeAlerts = [];
  bool _chaosMode = true; // Auto-trigger Bed 3 critical alarm on start
  bool get chaosMode => _chaosMode;

  final AudioAlertService _audioAlertService = AudioAlertService();

  MockTelemetryService() {
    _initInitialState();
  }

  void _initInitialState() {
    final now = DateTime.now();

    // Bed 01 - Elena Rostova (Optimal Post-Op)
    _currentTelemetry['bed_01'] = TelemetryData(
      bedId: 'bed_01',
      heartRate: 72,
      spo2: 99,
      temperature: 36.8,
      respiratoryRate: 16,
      bloodPressureSys: 118,
      bloodPressureDia: 76,
      timestamp: now,
      recentBpmHistory: [70, 71, 72, 73, 72, 71, 72, 74, 73, 72, 72, 73, 71, 72, 72],
      recentSpo2History: [99, 99, 98, 99, 99, 100, 99, 99, 98, 99, 99, 99, 99, 99, 99],
      recentTempHistory: [36.7, 36.7, 36.8, 36.8, 36.8, 36.8, 36.9, 36.8, 36.8, 36.8, 36.8, 36.8, 36.8, 36.8, 36.8],
    );
    _currentNodes['bed_01'] = NodeStatus(
      bedId: 'bed_01',
      rssi: -58,
      batteryPercent: 96,
      isOnline: true,
      lastSeen: now,
    );

    // Bed 02 - Marcus Vance (Checking / Mild Respiratory)
    _currentTelemetry['bed_02'] = TelemetryData(
      bedId: 'bed_02',
      heartRate: 88,
      spo2: 94,
      temperature: 37.6,
      respiratoryRate: 20,
      bloodPressureSys: 132,
      bloodPressureDia: 84,
      timestamp: now,
      recentBpmHistory: [82, 84, 85, 87, 88, 90, 89, 88, 86, 88, 89, 91, 88, 87, 88],
      recentSpo2History: [95, 95, 94, 94, 93, 94, 94, 95, 94, 94, 93, 94, 94, 94, 94],
      recentTempHistory: [37.4, 37.5, 37.5, 37.6, 37.6, 37.6, 37.7, 37.6, 37.6, 37.6, 37.6, 37.6, 37.7, 37.6, 37.6],
    );
    _currentNodes['bed_02'] = NodeStatus(
      bedId: 'bed_02',
      rssi: -64,
      batteryPercent: 88,
      isOnline: true,
      lastSeen: now,
    );

    // Bed 03 - David Chen (Critical Observation)
    _currentTelemetry['bed_03'] = TelemetryData(
      bedId: 'bed_03',
      heartRate: 118,
      spo2: 88,
      temperature: 38.6,
      respiratoryRate: 26,
      bloodPressureSys: 94,
      bloodPressureDia: 60,
      timestamp: now,
      recentBpmHistory: [108, 110, 112, 115, 116, 118, 120, 122, 119, 118, 117, 118, 121, 118, 118],
      recentSpo2History: [91, 90, 90, 89, 88, 88, 87, 86, 88, 89, 88, 87, 88, 88, 88],
      recentTempHistory: [38.2, 38.3, 38.4, 38.4, 38.5, 38.5, 38.6, 38.6, 38.7, 38.6, 38.6, 38.6, 38.6, 38.6, 38.6],
    );
    _currentNodes['bed_03'] = NodeStatus(
      bedId: 'bed_03',
      rssi: -78,
      batteryPercent: 74,
      isOnline: true,
      lastSeen: now,
    );

    // Initial critical alert for Bed 03
    _activeAlerts.add(
      AlertIncident(
        id: 'ALT-${now.millisecondsSinceEpoch}',
        bedId: 'bed_03',
        patientName: 'David Chen',
        severity: AlertSeverity.critical,
        triggerReason: 'Sustained SpO2 < 88% for 15s (Hypoxemia)',
        timestamp: now,
        secondsRemaining: 58,
        escalationLevel: 1,
      ),
    );

    // Play warning or critical alarm
    _audioAlertService.startCriticalAlarm();
  }

  void start() {
    _tickerTimer?.cancel();
    _countdownTimer?.cancel();

    // 1.5s real-time telemetry fluctuations
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _tickTelemetry();
    });

    // 1s countdown for auto-escalation timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickCountdowns();
    });

    // Emit initial states
    _emitAll();
  }

  void stop() {
    _tickerTimer?.cancel();
    _countdownTimer?.cancel();
    _audioAlertService.stopCriticalAlarm();
  }

  void toggleChaosMode(bool enable) {
    _chaosMode = enable;
    if (_chaosMode && _activeAlerts.isEmpty) {
      triggerTestAlarm('bed_03', 'Critical Tachycardia & SpO2 Drop (87%)');
    }
  }

  void triggerTestAlarm(String bedId, String reason) {
    final now = DateTime.now();
    final patientName = bedId == 'bed_01'
        ? 'Elena Rostova'
        : (bedId == 'bed_02' ? 'Marcus Vance' : 'David Chen');

    final alert = AlertIncident(
      id: 'ALT-${now.millisecondsSinceEpoch}',
      bedId: bedId,
      patientName: patientName,
      severity: AlertSeverity.critical,
      triggerReason: reason,
      timestamp: now,
      secondsRemaining: 60,
      escalationLevel: 1,
    );

    _activeAlerts.insert(0, alert);
    _audioAlertService.startCriticalAlarm();
    _alertsController.add(List.from(_activeAlerts));
  }

  void acknowledgeAlert(String alertId, String nurseName) {
    final index = _activeAlerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _activeAlerts[index] = _activeAlerts[index].copyWith(
        isAcknowledged: true,
        acknowledgedBy: nurseName,
      );
      // Silence critical siren upon acknowledgment
      _audioAlertService.stopCriticalAlarm();
      _alertsController.add(List.from(_activeAlerts));
    }
  }

  void clearAlert(String alertId) {
    _activeAlerts.removeWhere((a) => a.id == alertId);
    if (_activeAlerts.where((a) => a.severity == AlertSeverity.critical && !a.isAcknowledged).isEmpty) {
      _audioAlertService.stopCriticalAlarm();
    }
    _alertsController.add(List.from(_activeAlerts));
  }

  void _tickTelemetry() {
    final now = DateTime.now();

    // Bed 01: Stable sinus rhythm (70-74 bpm, 98-100% SpO2)
    _currentTelemetry['bed_01'] = _fluctuate(
      _currentTelemetry['bed_01']!,
      targetBpm: 72,
      targetSpo2: 99,
      targetTemp: 36.8,
      bpmVariance: 2,
      spo2Variance: 1,
      now: now,
    );

    // Bed 02: Moderate COPD (85-92 bpm, 93-95% SpO2)
    _currentTelemetry['bed_02'] = _fluctuate(
      _currentTelemetry['bed_02']!,
      targetBpm: 88,
      targetSpo2: 94,
      targetTemp: 37.6,
      bpmVariance: 3,
      spo2Variance: 1,
      now: now,
    );

    // Bed 03: Acute Sepsis / Hypoxia (114-122 bpm, 86-90% SpO2)
    _currentTelemetry['bed_03'] = _fluctuate(
      _currentTelemetry['bed_03']!,
      targetBpm: _chaosMode ? 118 : 84,
      targetSpo2: _chaosMode ? 88 : 96,
      targetTemp: _chaosMode ? 38.6 : 37.1,
      bpmVariance: 4,
      spo2Variance: 2,
      now: now,
    );

    // Subtly fluctuate RSSI
    for (final bedId in _currentNodes.keys) {
      final node = _currentNodes[bedId]!;
      final rssiDelta = _random.nextInt(3) - 1;
      _currentNodes[bedId] = node.copyWith(
        rssi: (node.rssi + rssiDelta).clamp(-90, -45),
        lastSeen: now,
      );
    }

    _emitAll();
  }

  TelemetryData _fluctuate(
    TelemetryData current, {
    required int targetBpm,
    required int targetSpo2,
    required double targetTemp,
    required int bpmVariance,
    required int spo2Variance,
    required DateTime now,
  }) {
    final deltaBpm = (_random.nextInt(bpmVariance * 2 + 1) - bpmVariance);
    final deltaSpo2 = (_random.nextInt(spo2Variance * 2 + 1) - spo2Variance);
    final deltaTemp = ((_random.nextDouble() * 0.2) - 0.1);

    final newBpm = (targetBpm + deltaBpm).clamp(40, 180);
    final newSpo2 = (targetSpo2 + deltaSpo2).clamp(75, 100);
    final newTemp = double.parse((targetTemp + deltaTemp).toStringAsFixed(1)).clamp(35.0, 41.0);

    final bpmHistory = List<double>.from(current.recentBpmHistory);
    if (bpmHistory.length >= 15) bpmHistory.removeAt(0);
    bpmHistory.add(newBpm.toDouble());

    final spo2History = List<double>.from(current.recentSpo2History);
    if (spo2History.length >= 15) spo2History.removeAt(0);
    spo2History.add(newSpo2.toDouble());

    final tempHistory = List<double>.from(current.recentTempHistory);
    if (tempHistory.length >= 15) tempHistory.removeAt(0);
    tempHistory.add(newTemp);

    return current.copyWith(
      heartRate: newBpm,
      spo2: newSpo2,
      temperature: newTemp,
      timestamp: now,
      recentBpmHistory: bpmHistory,
      recentSpo2History: spo2History,
      recentTempHistory: tempHistory,
    );
  }

  void _tickCountdowns() {
    bool hasChanged = false;
    for (int i = 0; i < _activeAlerts.length; i++) {
      final alert = _activeAlerts[i];
      if (!alert.isAcknowledged) {
        if (alert.secondsRemaining > 0) {
          _activeAlerts[i] = alert.copyWith(secondsRemaining: alert.secondsRemaining - 1);
          hasChanged = true;
        } else {
          // Auto-escalate to next tier (L1 -> L2 Supervisor, or L2 -> L3 Code Blue)
          if (alert.escalationLevel < 3) {
            _activeAlerts[i] = alert.copyWith(
              escalationLevel: alert.escalationLevel + 1,
              secondsRemaining: 60, // reset for next tier
            );
            hasChanged = true;
            // Play critical alarm tone on auto-escalation
            _audioAlertService.startCriticalAlarm();
          }
        }
      }
    }

    if (hasChanged) {
      _alertsController.add(List.from(_activeAlerts));
    }
  }

  void _emitAll() {
    _telemetryController.add(Map.from(_currentTelemetry));
    _nodesController.add(Map.from(_currentNodes));
    _alertsController.add(List.from(_activeAlerts));
    _gatewayController.add(GatewayStatus(lastHeartbeat: DateTime.now()));
  }

  void dispose() {
    stop();
    _telemetryController.close();
    _nodesController.close();
    _alertsController.close();
    _gatewayController.close();
  }
}
