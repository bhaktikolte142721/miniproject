enum PatientStatus {
  optimal,
  checking,
  critical,
}

/// Clinical profile of a monitored acute care patient.
class Patient {
  final String id;
  final String bedId; // "bed_01", "bed_02", "bed_03"
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
    required this.avatarUrl,
  });

  String get bedLabel {
    switch (bedId) {
      case 'bed_01':
        return 'Bed 01';
      case 'bed_02':
        return 'Bed 02';
      case 'bed_03':
        return 'Bed 03';
      default:
        return bedId.toUpperCase();
    }
  }

  Patient copyWith({
    PatientStatus? status,
    String? assignedNurse,
  }) {
    return Patient(
      id: id,
      bedId: bedId,
      name: name,
      age: age,
      gender: gender,
      assignedNurse: assignedNurse ?? this.assignedNurse,
      attendingPhysician: attendingPhysician,
      diagnosis: diagnosis,
      admissionDate: admissionDate,
      bloodType: bloodType,
      status: status ?? this.status,
      avatarUrl: avatarUrl,
    );
  }
}
