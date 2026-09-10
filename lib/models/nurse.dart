class Nurse {
  final String id;
  final String name;
  final String registrationNumber; // e.g. "RN #88192"
  final String designation;        // e.g. "Lead Triage Nurse"
  final String ward;               // e.g. "Ward 3B Telemetry"
  final String shift;              // e.g. "Morning (07:00 - 15:00)"
  final String initials;           // e.g. "AR"
  final bool isOnDuty;

  const Nurse({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.designation,
    required this.ward,
    required this.shift,
    required this.initials,
    this.isOnDuty = false,
  });

  Nurse copyWith({
    String? id,
    String? name,
    String? registrationNumber,
    String? designation,
    String? ward,
    String? shift,
    String? initials,
    bool? isOnDuty,
  }) {
    return Nurse(
      id: id ?? this.id,
      name: name ?? this.name,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      designation: designation ?? this.designation,
      ward: ward ?? this.ward,
      shift: shift ?? this.shift,
      initials: initials ?? this.initials,
      isOnDuty: isOnDuty ?? this.isOnDuty,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'registrationNumber': registrationNumber,
    'designation': designation,
    'ward': ward,
    'shift': shift,
    'initials': initials,
    'isOnDuty': isOnDuty,
  };

  factory Nurse.fromJson(Map<String, dynamic> json) => Nurse(
    id: json['id'] as String,
    name: json['name'] as String,
    registrationNumber: json['registrationNumber'] as String,
    designation: json['designation'] as String,
    ward: json['ward'] as String,
    shift: json['shift'] as String,
    initials: json['initials'] as String,
    isOnDuty: json['isOnDuty'] as bool? ?? false,
  );
}
