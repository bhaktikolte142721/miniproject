import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient.dart';
import '../models/telemetry_data.dart';
import '../models/node_status.dart';
import '../services/mock_telemetry_service.dart';
import 'telemetry_mode_provider.dart';

/// Singleton instance of autonomous MockTelemetryService
final mockTelemetryServiceProvider = Provider<MockTelemetryService>((ref) {
  final service = MockTelemetryService();
  service.start();
  ref.onDispose(() => service.dispose());
  return service;
});

/// List of monitored acute care patients in Ward 3B (6 beds matching clinical database)
final patientsListProvider = Provider<List<Patient>>((ref) {
  final now = DateTime.now();
  return [
    Patient(
      id: 'P-8821',
      bedId: 'bed_01',
      name: 'Priya Sharma',
      age: 34,
      gender: 'Female',
      assignedNurse: 'Sister Sunita Rao, RN',
      attendingPhysician: 'Dr. Aditi Deshmukh, MD',
      diagnosis: 'Post-Op Laparoscopic Cholecystectomy',
      admissionDate: now.subtract(const Duration(days: 1)),
      bloodType: 'A+',
      status: PatientStatus.optimal,
      avatarUrl: 'assets/images/vital_heart_3d.png',
    ),
    Patient(
      id: 'P-8822',
      bedId: 'bed_02',
      name: 'Rajesh Kumar',
      age: 58,
      gender: 'Male',
      assignedNurse: 'Nurse Rohan Joshi, RN',
      attendingPhysician: 'Dr. Vikram Malhotra, MD',
      diagnosis: 'Acute COPD Exacerbation & Bronchospasm',
      admissionDate: now.subtract(const Duration(days: 2)),
      bloodType: 'O+',
      status: PatientStatus.checking,
      avatarUrl: 'assets/images/pulse_oximeter_3d.png',
    ),
    Patient(
      id: 'P-8823',
      bedId: 'bed_03',
      name: 'Amit Patel',
      age: 62,
      gender: 'Male',
      assignedNurse: 'Sister Sunita Rao, RN',
      attendingPhysician: 'Dr. Arvind Swaminathan, MD (Pulmonology)',
      diagnosis: 'Severe Bilateral Pneumonia & Sepsis Protocol',
      admissionDate: now.subtract(const Duration(hours: 14)),
      bloodType: 'B+',
      status: PatientStatus.critical,
      avatarUrl: 'assets/images/vital_monitor_3d.png',
    ),
    Patient(
      id: 'P-8824',
      bedId: 'bed_04',
      name: 'Sneha Kulkarni',
      age: 35,
      gender: 'Female',
      assignedNurse: 'Nurse Kavita Shinde, RN',
      attendingPhysician: 'Dr. Aditi Deshmukh, MD',
      diagnosis: 'Elective Observation • Post-Op Room 307',
      admissionDate: now.subtract(const Duration(hours: 8)),
      bloodType: 'O+',
      status: PatientStatus.optimal,
      avatarUrl: 'assets/images/vital_heart_3d.png',
    ),
    Patient(
      id: 'P-8825',
      bedId: 'bed_05',
      name: 'Manoj Tiwari',
      age: 50,
      gender: 'Male',
      assignedNurse: 'Nurse Rohan Joshi, RN',
      attendingPhysician: 'Dr. Vikram Malhotra, MD',
      diagnosis: 'Cardiac Rehab Post-Stent • Room 308',
      admissionDate: now.subtract(const Duration(days: 1)),
      bloodType: 'AB+',
      status: PatientStatus.optimal,
      avatarUrl: 'assets/images/pulse_oximeter_3d.png',
    ),
    Patient(
      id: 'P-8826',
      bedId: 'bed_06',
      name: 'Harish Chandra',
      age: 67,
      gender: 'Male',
      assignedNurse: 'Sister Sunita Rao, RN',
      attendingPhysician: 'Dr. Arvind Swaminathan, MD',
      diagnosis: 'Orthopedic Knee Arthroplasty • Room 309',
      admissionDate: now.subtract(const Duration(days: 3)),
      bloodType: 'A+',
      status: PatientStatus.optimal,
      avatarUrl: 'assets/images/vital_monitor_3d.png',
    ),
  ];
});

// Cache for rolling vital histories per bed when streaming live from backend
final _liveVitalsHistoryCache = <String, Map<String, List<double>>>{};

/// Real-time stream of multi-patient telemetry feeds (supports both Live and Simulation)
final telemetryStreamProvider = StreamProvider<Map<String, TelemetryData>>((ref) {
  final modeState = ref.watch(telemetryModeProvider);

  if (modeState.isSimulation) {
    final mockService = ref.watch(mockTelemetryServiceProvider);
    return mockService.telemetryStream;
  }

  // Live Mode: Consume real Socket.IO events from Node.js backend
  final socketService = ref.watch(socketServiceProvider);

  return socketService.onVitalsUpdate.map((rawData) {
    final result = <String, TelemetryData>{};

    for (final entry in rawData.entries) {
      final bedId = entry.key;
      if (entry.value is Map) {
        final bedJson = Map<String, dynamic>.from(entry.value as Map);
        final bedHistory = _liveVitalsHistoryCache.putIfAbsent(bedId, () => {
          'bpm': <double>[],
          'spo2': <double>[],
          'temp': <double>[],
        });

        final telemetry = TelemetryData.fromJson(
          bedId,
          bedJson,
          previousBpmHistory: bedHistory['bpm']!,
          previousSpo2History: bedHistory['spo2']!,
          previousTempHistory: bedHistory['temp']!,
        );

        bedHistory['bpm'] = telemetry.recentBpmHistory;
        bedHistory['spo2'] = telemetry.recentSpo2History;
        bedHistory['temp'] = telemetry.recentTempHistory;

        result[bedId] = telemetry;
      }
    }
    return result;
  });
});

/// Real-time stream of nRF24 node radio and battery statuses
final nodeStatusStreamProvider = StreamProvider<Map<String, NodeStatus>>((ref) {
  final modeState = ref.watch(telemetryModeProvider);

  if (modeState.isSimulation) {
    final mockService = ref.watch(mockTelemetryServiceProvider);
    return mockService.nodesStream;
  }

  // Live Mode
  final socketService = ref.watch(socketServiceProvider);
  return socketService.onNodeStatus.map((rawData) {
    final result = <String, NodeStatus>{};
    for (final entry in rawData.entries) {
      if (entry.value is Map) {
        result[entry.key] = NodeStatus.fromJson(
          entry.key,
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }
    return result;
  });
});

/// ESP32 Ward Gateway status stream
final gatewayStatusStreamProvider = StreamProvider<GatewayStatus>((ref) {
  final modeState = ref.watch(telemetryModeProvider);

  if (modeState.isSimulation) {
    final mockService = ref.watch(mockTelemetryServiceProvider);
    return mockService.gatewayStream;
  }

  // Live Mode: reflect actual Socket.IO connection status
  final socketService = ref.watch(socketServiceProvider);

  return Stream.multi((controller) {
    void emitStatus() {
      controller.add(GatewayStatus(
        isConnected: socketService.isConnected,
        gatewayId: 'ESP32-WARD-3B-LIVE',
        activeNodesCount: 6,
        uptimeSeconds: 0,
        ipAddress: socketService.serverUrl,
        lastHeartbeat: DateTime.now(),
      ));
    }

    emitStatus();
    final sub = socketService.onStatusChanged.listen((_) => emitStatus());
    controller.onCancel = () => sub.cancel();
  });
});
