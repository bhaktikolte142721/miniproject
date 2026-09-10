import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient.dart';
import '../models/telemetry_data.dart';
import '../models/node_status.dart';
import '../services/mock_telemetry_service.dart';
import '../services/socket_service.dart';

// ─── Default seed patients ────────────────────────────────────────────────────
List<Patient> _defaultPatients() {
  final now = DateTime.now();
  return [
    Patient(
      id: 'P-8821',
      bedId: 'bed_01',
      name: 'Priya Sharma',
      age: 34,
      gender: 'Female',
      assignedNurse: 'Sister Ananya Roy, RN',
      attendingPhysician: 'Dr. Vikram Deshmukh, MD',
      diagnosis: 'Post-Op Laparoscopic Cholecystectomy',
      admissionDate: now.subtract(const Duration(days: 1)),
      bloodType: 'A+',
      status: PatientStatus.optimal,
      avatarUrl: 'assets/images/vital_heart_3d.png',
    ),
    Patient(
      id: 'P-8822',
      bedId: 'bed_02',
      name: 'Rajesh Kulkarni',
      age: 58,
      gender: 'Male',
      assignedNurse: 'Brother Deepak Nair, RN',
      attendingPhysician: 'Dr. Arjun Mehta, MS',
      diagnosis: 'Acute COPD Exacerbation & Bronchospasm',
      admissionDate: now.subtract(const Duration(days: 2)),
      bloodType: 'O+',
      status: PatientStatus.checking,
      avatarUrl: 'assets/images/pulse_oximeter_3d.png',
    ),
    Patient(
      id: 'P-8823',
      bedId: 'bed_03',
      name: 'Sunita Patel',
      age: 62,
      gender: 'Female',
      assignedNurse: 'Sister Ananya Roy, RN',
      attendingPhysician: 'Dr. Aditi Mukherjee, MD (Pulmonology)',
      diagnosis: 'Severe Bilateral Pneumonia & Sepsis Protocol',
      admissionDate: now.subtract(const Duration(hours: 14)),
      bloodType: 'B+',
      status: PatientStatus.critical,
      avatarUrl: 'assets/images/vital_monitor_3d.png',
    ),
  ];
}

// ─── PatientNotifier: manages live list of admitted patients ─────────────────
class PatientNotifier extends StateNotifier<List<Patient>> {
  PatientNotifier() : super(_defaultPatients());

  /// Admit a new patient to the ward.
  void admitPatient(Patient patient) {
    state = [...state, patient];
  }

  /// Discharge a patient by their ID.
  void dischargePatient(String patientId) {
    state = state.where((p) => p.id != patientId).toList();
  }

  /// Update the status of an existing patient.
  void updateStatus(String patientId, PatientStatus status) {
    state = state.map((p) => p.id == patientId ? p.copyWith(status: status) : p).toList();
  }

  /// Generate the next available bed ID.
  String nextBedId() {
    final occupied = state.map((p) => p.bedId).toSet();
    for (int i = 1; i <= 20; i++) {
      final id = 'bed_${i.toString().padLeft(2, '0')}';
      if (!occupied.contains(id)) return id;
    }
    return 'bed_${state.length + 1}';
  }

  /// Generate the next patient ID.
  String nextPatientId() {
    if (state.isEmpty) return 'P-8821';
    final ids = state.map((p) {
      final n = int.tryParse(p.id.replaceAll('P-', '')) ?? 8820;
      return n;
    }).toList();
    ids.sort();
    return 'P-${ids.last + 1}';
  }
}

/// StateNotifierProvider: the live list of admitted patients
final patientsProvider = StateNotifierProvider<PatientNotifier, List<Patient>>(
  (ref) => PatientNotifier(),
);

/// Legacy alias so existing screens that watch `patientsListProvider` still compile
final patientsListProvider = Provider<List<Patient>>(
  (ref) => ref.watch(patientsProvider),
);

// ─── Telemetry Service & Real-Time Socket Gateway ───────────────────────────
final socketServiceProvider = Provider<SocketService>((ref) {
  final socket = SocketService();
  socket.connect();
  ref.onDispose(() => socket.dispose());
  return socket;
});

final mockTelemetryServiceProvider = Provider<MockTelemetryService>((ref) {
  final service = MockTelemetryService();
  final socket = ref.watch(socketServiceProvider);
  service.attachSocketService(socket);
  service.start();
  ref.onDispose(() => service.dispose());
  return service;
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
