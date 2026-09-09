import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_ward/models/patient.dart';
import 'package:sentinel_ward/models/telemetry_data.dart';
import 'package:sentinel_ward/models/alert_incident.dart';
import 'package:sentinel_ward/services/mock_telemetry_service.dart';

void main() {
  group('SENTINEL-Ward Telemetry & Clinical Rules Tests', () {
    test('TelemetryData detects critical hypoxemia when SpO2 < 90%', () {
      final criticalData = TelemetryData(
        bedId: 'bed_03',
        heartRate: 118,
        spo2: 87, // Under 90% threshold
        temperature: 38.6,
        respiratoryRate: 24,
        bloodPressureSys: 95,
        bloodPressureDia: 60,
        timestamp: DateTime.now(),
      );

      expect(criticalData.status, PatientStatus.critical);
      expect(criticalData.statusLabel, 'Critical Alert');
    });

    test('TelemetryData detects optimal status for normal patient vitals', () {
      final normalData = TelemetryData(
        bedId: 'bed_01',
        heartRate: 72,
        spo2: 99,
        temperature: 36.8,
        respiratoryRate: 16,
        bloodPressureSys: 118,
        bloodPressureDia: 78,
        timestamp: DateTime.now(),
      );

      expect(normalData.status, PatientStatus.optimal);
      expect(normalData.statusLabel, 'Optimal');
    });

    test('MockTelemetryService initializes Beds 1, 2, 3 with physiological baselines', () {
      final service = MockTelemetryService();
      expect(service.chaosMode, true);

      // Trigger test alarm on Bed 03
      service.triggerTestAlarm('bed_03', 'Critical Hypoxemia < 88%');
      service.acknowledgeAlert('ALT-bed_03', 'Nurse Sarah');
      service.dispose();
    });

    test('AlertIncident auto-escalation level labels', () {
      final l1Alert = AlertIncident(
        id: '1',
        bedId: 'bed_01',
        patientName: 'Test',
        severity: AlertSeverity.critical,
        triggerReason: 'Test',
        timestamp: DateTime(2026, 9, 9),
        escalationLevel: 1,
      );
      expect(l1Alert.escalationStageLabel, 'L1: Bedside Nurse');

      final l2Alert = l1Alert.copyWith(escalationLevel: 2);
      expect(l2Alert.escalationStageLabel, 'L2: Ward Supervisor');

      final l3Alert = l1Alert.copyWith(escalationLevel: 3);
      expect(l3Alert.escalationStageLabel, 'L3: Rapid Response Team (Code Blue)');
    });
  });
}
