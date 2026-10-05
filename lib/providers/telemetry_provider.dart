import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient.dart';
import '../models/telemetry_data.dart';
import '../models/node_status.dart';
import '../services/mock_telemetry_service.dart';

/// Singleton instance of autonomous MockTelemetryService
final mockTelemetryServiceProvider = Provider<MockTelemetryService>((ref) {
  final service = MockTelemetryService();
  service.start();
  ref.onDispose(() => service.dispose());
  return service;
});

/// List of monitored acute care patients in Ward 3B
final patientsListProvider = Provider<List<Patient>>((ref) {
  final now = DateTime.now();
  return [
    Patient(
      id: 'P-8821',
      bedId: 'bed_01',
      name: 'Elena Rostova',
      age: 34,
      gender: 'Female',
      assignedNurse: 'Nurse Sarah Jenkins, RN',
      attendingPhysician: 'Dr. Sarah Johnson, MD',
      diagnosis: 'Post-Op Laparoscopic Cholecystectomy',
      admissionDate: now.subtract(const Duration(days: 1)),
      bloodType: 'A+',
      status: PatientStatus.optimal,
      avatarUrl: 'assets/images/vital_heart_3d.png',
    ),
    Patient(
      id: 'P-8822',
      bedId: 'bed_02',
      name: 'Marcus Vance',
      age: 58,
      gender: 'Male',
      assignedNurse: 'Nurse Michael Chen, RN',
      attendingPhysician: 'Dr. Robert Bell, MD',
      diagnosis: 'Acute COPD Exacerbation & Bronchospasm',
      admissionDate: now.subtract(const Duration(days: 2)),
      bloodType: 'O+',
      status: PatientStatus.checking,
      avatarUrl: 'assets/images/pulse_oximeter_3d.png',
    ),
    Patient(
      id: 'P-8823',
      bedId: 'bed_03',
      name: 'David Chen',
      age: 62,
      gender: 'Male',
      assignedNurse: 'Nurse Sarah Jenkins, RN',
      attendingPhysician: 'Dr. Aris Thorne, MD (Pulmonology)',
      diagnosis: 'Severe Bilateral Pneumonia & Sepsis Protocol',
      admissionDate: now.subtract(const Duration(hours: 14)),
      bloodType: 'B+',
      status: PatientStatus.critical,
      avatarUrl: 'assets/images/vital_monitor_3d.png',
    ),
  ];
});

/// Real-time stream of multi-patient telemetry feeds
final telemetryStreamProvider = StreamProvider<Map<String, TelemetryData>>((ref) {
  final service = ref.watch(mockTelemetryServiceProvider);
  return service.telemetryStream;
});

/// Real-time stream of nRF24 node radio and battery statuses
final nodeStatusStreamProvider = StreamProvider<Map<String, NodeStatus>>((ref) {
  final service = ref.watch(mockTelemetryServiceProvider);
  return service.nodesStream;
});

/// ESP32 Ward Gateway status stream
final gatewayStatusStreamProvider = StreamProvider<GatewayStatus>((ref) {
  final service = ref.watch(mockTelemetryServiceProvider);
  return service.gatewayStream;
});
