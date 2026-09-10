import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/patient.dart';
import '../../providers/telemetry_provider.dart';

/// Bottom sheet for admitting a new patient to the ward.
/// Shows a clean form with validation and a teal "Admit" CTA.
class PatientAdmissionSheet extends ConsumerStatefulWidget {
  const PatientAdmissionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PatientAdmissionSheet(),
    );
  }

  @override
  ConsumerState<PatientAdmissionSheet> createState() => _PatientAdmissionSheetState();
}

class _PatientAdmissionSheetState extends ConsumerState<PatientAdmissionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _ageCtrl         = TextEditingController();
  final _diagnosisCtrl   = TextEditingController();
  final _nurseCtrl       = TextEditingController();
  final _physicianCtrl   = TextEditingController();

  String _gender    = 'Male';
  String _bloodType = 'A+';
  bool _submitting  = false;

  static const _genders    = ['Male', 'Female', 'Other'];
  static const _bloodTypes = ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _diagnosisCtrl.dispose();
    _nurseCtrl.dispose();
    _physicianCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final notifier = ref.read(patientsProvider.notifier);
    final bedId    = notifier.nextBedId();
    final patId    = notifier.nextPatientId();

    final patient = Patient(
      id: patId,
      bedId: bedId,
      name: _nameCtrl.text.trim(),
      age: int.parse(_ageCtrl.text.trim()),
      gender: _gender,
      assignedNurse: _nurseCtrl.text.trim().isEmpty
          ? 'Nurse On-Duty'
          : _nurseCtrl.text.trim(),
      attendingPhysician: _physicianCtrl.text.trim().isEmpty
          ? 'Attending Physician'
          : _physicianCtrl.text.trim(),
      diagnosis: _diagnosisCtrl.text.trim(),
      admissionDate: DateTime.now(),
      bloodType: _bloodType,
      status: PatientStatus.optimal,
      avatarUrl: 'assets/images/vital_heart_3d.png',
    );

    notifier.admitPatient(patient);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${patient.name} admitted to ${patient.bedLabel}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.alertStable,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.mintTealGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [AppColors.clayPillShadow],
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admit New Patient', style: AppTextStyles.headlineSmall),
                      Text('Ward 3B Acute Care', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.chipInactive,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          const Divider(color: AppColors.cardBorder, height: 24),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    _label('Full Name *'),
                    _field(
                      controller: _nameCtrl,
                      hint: 'e.g. Ramesh Patel',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Age + Gender row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Age *'),
                              _field(
                                controller: _ageCtrl,
                                hint: '45',
                                icon: Icons.cake_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  final n = int.tryParse(v ?? '');
                                  if (n == null || n < 1 || n > 120) return 'Enter valid age';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Gender'),
                              _dropdown(
                                value: _gender,
                                items: _genders,
                                icon: Icons.wc_rounded,
                                onChanged: (v) => setState(() => _gender = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Blood Type + auto Bed row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Blood Type'),
                              _dropdown(
                                value: _bloodType,
                                items: _bloodTypes,
                                icon: Icons.water_drop_outlined,
                                onChanged: (v) => setState(() => _bloodType = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Bed (auto-assigned)'),
                              Consumer(builder: (ctx, r, _) {
                                final bed = r.read(patientsProvider.notifier).nextBedId();
                                return Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: AppColors.mintLight,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.primaryMint.withValues(alpha: 0.4)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    bed.replaceAll('_', ' ').toUpperCase(),
                                    style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryTeal),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Diagnosis
                    _label('Primary Diagnosis *'),
                    _field(
                      controller: _diagnosisCtrl,
                      hint: 'e.g. Acute Myocardial Infarction',
                      icon: Icons.medical_information_outlined,
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Diagnosis required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Assigned Nurse
                    _label('Assigned Nurse'),
                    _field(
                      controller: _nurseCtrl,
                      hint: 'Sister Ananya Roy, RN',
                      icon: Icons.local_hospital_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Attending Physician
                    _label('Attending Physician'),
                    _field(
                      controller: _physicianCtrl,
                      hint: 'Dr. Vikram Deshmukh, MD',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMint,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_circle_outline_rounded, size: 20),
                                  const SizedBox(width: 10),
                                  Text('Admit Patient', style: AppTextStyles.buttonText),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTextStyles.formLabel),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.formHint,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryMint, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.alertCritical, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryMint, width: 1.8),
        ),
      ),
    );
  }
}
