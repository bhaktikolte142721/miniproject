import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nurse.dart';

List<Nurse> _initialNurses() {
  return [
    const Nurse(
      id: 'NURSE-01',
      name: 'Sister Ananya Roy',
      registrationNumber: 'RN #88192',
      designation: 'Lead Triage Nurse',
      ward: 'Ward 3B Telemetry',
      shift: 'Morning (07:00 - 15:00)',
      initials: 'AR',
      isOnDuty: true,
    ),
    const Nurse(
      id: 'NURSE-02',
      name: 'Brother Deepak Nair',
      registrationNumber: 'RN #77410',
      designation: 'ICU Critical Care Nurse',
      ward: 'Ward 3B Telemetry',
      shift: 'Night (23:00 - 07:00)',
      initials: 'DN',
      isOnDuty: false,
    ),
    const Nurse(
      id: 'NURSE-03',
      name: 'Sister Sunita Rao',
      registrationNumber: 'RN #99304',
      designation: 'Senior Nursing Officer',
      ward: 'Emergency Triage',
      shift: 'Evening (15:00 - 23:00)',
      initials: 'SR',
      isOnDuty: false,
    ),
    const Nurse(
      id: 'NURSE-04',
      name: 'Sister Priya Deshmukh',
      registrationNumber: 'RN #66219',
      designation: 'Post-Op Specialist Nurse',
      ward: 'Surgical Step-Down',
      shift: 'Morning (07:00 - 15:00)',
      initials: 'PD',
      isOnDuty: false,
    ),
  ];
}

class NurseNotifier extends StateNotifier<List<Nurse>> {
  NurseNotifier() : super(_initialNurses());

  /// Switch the active on-duty nurse
  void switchOnDuty(String nurseId) {
    state = [
      for (final n in state)
        n.copyWith(isOnDuty: n.id == nurseId),
    ];
  }

  /// Register a new nurse into the ward roster
  void registerNurse({
    required String name,
    required String registrationNumber,
    required String designation,
    required String ward,
    required String shift,
    bool setOnDuty = true,
  }) {
    // Generate initials (e.g. "Ananya Roy" -> "AR")
    final parts = name.trim().split(' ');
    String inits = 'RN';
    if (parts.length >= 2) {
      inits = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      inits = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }

    final newId = 'NURSE-${(state.length + 1).toString().padLeft(2, '0')}';
    final newNurse = Nurse(
      id: newId,
      name: name.trim(),
      registrationNumber: registrationNumber.trim(),
      designation: designation.trim(),
      ward: ward.trim(),
      shift: shift.trim(),
      initials: inits,
      isOnDuty: setOnDuty,
    );

    if (setOnDuty) {
      state = [
        for (final n in state) n.copyWith(isOnDuty: false),
        newNurse,
      ];
    } else {
      state = [...state, newNurse];
    }
  }
}

final nurseNotifierProvider = StateNotifierProvider<NurseNotifier, List<Nurse>>(
  (ref) => NurseNotifier(),
);

/// Currently active on-duty nurse
final activeNurseProvider = Provider<Nurse>((ref) {
  final list = ref.watch(nurseNotifierProvider);
  return list.firstWhere((n) => n.isOnDuty, orElse: () => list.first);
});
