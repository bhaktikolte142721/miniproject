enum AlertSeverity {
  critical,
  warning,
  info,
}

/// Clinical telemetry alarm incident with 60-second escalation countdown.
class AlertIncident {
  final String id;
  final String bedId;
  final String patientName;
  final AlertSeverity severity;
  final String triggerReason;
  final DateTime timestamp;
  final int secondsRemaining; // Auto-escalation countdown (default 60)
  final bool isAcknowledged;
  final String? acknowledgedBy;
  final int escalationLevel; // 1: Bedside, 2: Supervisor, 3: Code Blue

  const AlertIncident({
    required this.id,
    required this.bedId,
    required this.patientName,
    required this.severity,
    required this.triggerReason,
    required this.timestamp,
    this.secondsRemaining = 60,
    this.isAcknowledged = false,
    this.acknowledgedBy,
    this.escalationLevel = 1,
  });

  /// Factory constructor to parse real alarm incidents from backend Socket.IO
  factory AlertIncident.fromJson(Map<String, dynamic> json) {
    final severityStr = (json['severity'] ?? 'warning').toString().toLowerCase();
    AlertSeverity sev = AlertSeverity.warning;
    if (severityStr == 'critical') {
      sev = AlertSeverity.critical;
    } else if (severityStr == 'advisory' || severityStr == 'info') {
      sev = AlertSeverity.info;
    }

    DateTime parsedTimestamp = DateTime.now();
    if (json['timestamp'] != null || json['triggered_at'] != null) {
      final raw = (json['timestamp'] ?? json['triggered_at']).toString();
      parsedTimestamp = DateTime.tryParse(raw) ?? DateTime.now();
    }

    return AlertIncident(
      id: (json['id'] ?? json['alarm_id'] ?? '').toString(),
      bedId: (json['bedId'] ?? json['bed_id'] ?? '').toString(),
      patientName: (json['patientName'] ?? json['patient_name'] ?? 'Patient').toString(),
      severity: sev,
      triggerReason: (json['triggerReason'] ?? json['critical_condition'] ?? 'Telemetry alert').toString(),
      timestamp: parsedTimestamp,
      secondsRemaining: (json['secondsRemaining'] as num?)?.toInt() ?? 60,
      isAcknowledged: json['isAcknowledged'] == true || json['status'] == 'acknowledged',
      acknowledgedBy: json['acknowledgedBy']?.toString() ?? json['acknowledged_by']?.toString(),
      escalationLevel: (json['escalationLevel'] as num?)?.toInt() ?? (json['escalation_level'] as num?)?.toInt() ?? 1,
    );
  }

  String get escalationStageLabel {
    switch (escalationLevel) {
      case 1:
        return 'L1: Bedside Nurse';
      case 2:
        return 'L2: Ward Supervisor';
      case 3:
        return 'L3: Rapid Response Team (Code Blue)';
      default:
        return 'Escalated (L$escalationLevel)';
    }
  }

  AlertIncident copyWith({
    int? secondsRemaining,
    bool? isAcknowledged,
    String? acknowledgedBy,
    int? escalationLevel,
  }) {
    return AlertIncident(
      id: id,
      bedId: bedId,
      patientName: patientName,
      severity: severity,
      triggerReason: triggerReason,
      timestamp: timestamp,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      escalationLevel: escalationLevel ?? this.escalationLevel,
    );
  }
}
