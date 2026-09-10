import 'dart:convert';

enum PatientStatus {
  optimal,
  checking,
  critical,
}

extension PatientStatusExt on PatientStatus {
  String get label {
    switch (this) {
      case PatientStatus.optimal:  return 'Stable';
      case PatientStatus.checking: return 'Monitoring';
      case PatientStatus.critical: return 'Critical';
    }
  }
}

/// Clinical profile of a monitored acute care patient.
class Patient {
  final String id;
  final String bedId;       // "bed_01", "bed_02", "bed_03", etc.
  final String name;
  final int age;
  final String gender;
  final String assignedNurse;
  final String attendingPhysician;
  final String diagnosis;
  final DateTime admissionDate;
  final String bloodType;
  final PatientStatus status;
  final String avatarUrl;

  const Patient({
    required this.id,
    required this.bedId,
    required this.name,
    required this.age,
    required this.gender,
    required this.assignedNurse,
    required this.attendingPhysician,
    required this.diagnosis,
    required this.admissionDate,
    required this.bloodType,
    this.status = PatientStatus.optimal,
    this.avatarUrl = 'assets/images/vital_heart_3d.png',
  });

  String get bedLabel {
    final num = bedId.replaceAll(RegExp(r'[^0-9]'), '');
    return num.isNotEmpty ? 'Bed $num' : bedId.toUpperCase();
  }

  Patient copyWith({
    String? id,
    String? bedId,
    String? name,
    int? age,
    String? gender,
    String? assignedNurse,
    String? attendingPhysician,
    String? diagnosis,
    DateTime? admissionDate,
    String? bloodType,
    PatientStatus? status,
    String? avatarUrl,
  }) {
    return Patient(
      id: id ?? this.id,
      bedId: bedId ?? this.bedId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      assignedNurse: assignedNurse ?? this.assignedNurse,
      attendingPhysician: attendingPhysician ?? this.attendingPhysician,
      diagnosis: diagnosis ?? this.diagnosis,
      admissionDate: admissionDate ?? this.admissionDate,
      bloodType: bloodType ?? this.bloodType,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bedId': bedId,
    'name': name,
    'age': age,
    'gender': gender,
    'assignedNurse': assignedNurse,
    'attendingPhysician': attendingPhysician,
    'diagnosis': diagnosis,
    'admissionDate': admissionDate.toIso8601String(),
    'bloodType': bloodType,
    'status': status.index,
    'avatarUrl': avatarUrl,
  };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] as String,
    bedId: json['bedId'] as String,
    name: json['name'] as String,
    age: json['age'] as int,
    gender: json['gender'] as String,
    assignedNurse: json['assignedNurse'] as String,
    attendingPhysician: json['attendingPhysician'] as String,
    diagnosis: json['diagnosis'] as String,
    admissionDate: DateTime.parse(json['admissionDate'] as String),
    bloodType: json['bloodType'] as String,
    status: PatientStatus.values[json['status'] as int],
    avatarUrl: json['avatarUrl'] as String? ?? 'assets/images/vital_heart_3d.png',
  );

  String toJsonString() => jsonEncode(toJson());
}
