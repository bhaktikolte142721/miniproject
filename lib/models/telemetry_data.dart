import 'patient.dart';

/// Real-time multi-parameter physiological telemetry reading.
class TelemetryData {
  final String bedId;
  final int heartRate; // BPM (norm: 60 - 100)
  final int spo2; // % (norm: 95 - 100)
  final double temperature; // °C (norm: 36.5 - 37.5)
  final int respiratoryRate; // breaths/min (norm: 12 - 20)
  final int bloodPressureSys; // mmHg (norm: 90 - 120)
  final int bloodPressureDia; // mmHg (norm: 60 - 80)
  final DateTime timestamp;
  final List<double> recentBpmHistory;
  final List<double> recentSpo2History;
  final List<double> recentTempHistory;

  const TelemetryData({
    required this.bedId,
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.respiratoryRate,
    required this.bloodPressureSys,
    required this.bloodPressureDia,
    required this.timestamp,
    this.recentBpmHistory = const [],
    this.recentSpo2History = const [],
    this.recentTempHistory = const [],
  });

  /// Factory constructor to parse real telemetry JSON payload from backend Socket.IO
  factory TelemetryData.fromJson(
    String bedId,
    Map<String, dynamic> json, {
    List<double> previousBpmHistory = const [],
    List<double> previousSpo2History = const [],
    List<double> previousTempHistory = const [],
  }) {
    final hr = (json['heartRate'] as num?)?.toInt() ?? 75;
    final sp = (json['spo2'] as num?)?.toInt() ?? 98;
    final temp = (json['temperature'] as num?)?.toDouble() ?? 37.0;

    final bpmHistory = List<double>.from(previousBpmHistory);
    bpmHistory.add(hr.toDouble());
    if (bpmHistory.length > 25) bpmHistory.removeAt(0);

    final spo2History = List<double>.from(previousSpo2History);
    spo2History.add(sp.toDouble());
    if (spo2History.length > 25) spo2History.removeAt(0);

    final tempHistory = List<double>.from(previousTempHistory);
    tempHistory.add(temp);
    if (tempHistory.length > 25) tempHistory.removeAt(0);

    DateTime parsedTimestamp = DateTime.now();
    if (json['timestamp'] != null) {
      parsedTimestamp = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
    }

    return TelemetryData(
      bedId: bedId,
      heartRate: hr,
      spo2: sp,
      temperature: temp,
      respiratoryRate: (json['respiratoryRate'] as num?)?.toInt() ?? 16,
      bloodPressureSys: (json['bloodPressureSys'] as num?)?.toInt() ?? 120,
      bloodPressureDia: (json['bloodPressureDia'] as num?)?.toInt() ?? 80,
      timestamp: parsedTimestamp,
      recentBpmHistory: bpmHistory,
      recentSpo2History: spo2History,
      recentTempHistory: tempHistory,
    );
  }

  PatientStatus get status {
    if (spo2 < 90 || heartRate > 120 || heartRate < 48 || temperature > 38.3) {
      return PatientStatus.critical;
    }
    if (spo2 < 94 || heartRate > 100 || heartRate < 55 || temperature > 37.5) {
      return PatientStatus.checking;
    }
    return PatientStatus.optimal;
  }

  String get statusLabel {
    switch (status) {
      case PatientStatus.critical:
        return 'Critical Alert';
      case PatientStatus.checking:
        return 'Checking...';
      case PatientStatus.optimal:
        return 'Optimal';
    }
  }

  TelemetryData copyWith({
    int? heartRate,
    int? spo2,
    double? temperature,
    int? respiratoryRate,
    int? bloodPressureSys,
    int? bloodPressureDia,
    DateTime? timestamp,
    List<double>? recentBpmHistory,
    List<double>? recentSpo2History,
    List<double>? recentTempHistory,
  }) {
    return TelemetryData(
      bedId: bedId,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      temperature: temperature ?? this.temperature,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      bloodPressureSys: bloodPressureSys ?? this.bloodPressureSys,
      bloodPressureDia: bloodPressureDia ?? this.bloodPressureDia,
      timestamp: timestamp ?? this.timestamp,
      recentBpmHistory: recentBpmHistory ?? this.recentBpmHistory,
      recentSpo2History: recentSpo2History ?? this.recentSpo2History,
      recentTempHistory: recentTempHistory ?? this.recentTempHistory,
    );
  }
}
