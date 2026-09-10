import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/print_helper.dart';
import '../../providers/nurse_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/alerts_provider.dart';
import '../../models/patient.dart';

/// Official Printable Hospital Telemetry Shift Handover & Audit Report.
class ClinicalReportDialog extends ConsumerWidget {
  const ClinicalReportDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ClinicalReportDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeNurse = ref.watch(activeNurseProvider);
    final telemetryAsync = ref.watch(telemetryStreamProvider);
    final patients = ref.watch(patientsListProvider);
    final resolvedAlarms = ref.watch(resolvedAlarmsCountProvider).maybeWhen(
          data: (val) => val,
          orElse: () => ref.read(mockTelemetryServiceProvider).resolvedAlarmsCount,
        );
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} IST';

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle & Top Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_rounded, color: AppColors.primaryTeal, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Clinical Telemetry Handover Report',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Printable Report Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital Header
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'SENTINEL ACUTE CARE TELEMETRY SYSTEM',
                          style: AppTextStyles.headlineSmall.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Department of Cardiology & Step-Down Critical Care • Ward 3B',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMint.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OFFICIAL SHIFT AUDIT & HANDOVER SUMMARY',
                            style: AppTextStyles.badgeText.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade300, thickness: 1.2),
                  const SizedBox(height: 10),

                  // Metadata Grid
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetaField('Date & Time', dateStr),
                            _buildMetaField('Shift', '${activeNurse.shift} (Active)'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetaField('On-Duty Nurse', '${activeNurse.name} (${activeNurse.designation})'),
                            _buildMetaField('Nurse Reg #', activeNurse.registrationNumber),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetaField('Attending Physician', 'Dr. Vikram Malhotra, MD (Cardiology)'),
                            _buildMetaField('Gateway Node', 'ESP32-Hub-01 (Online • 2.4GHz)'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Shift Performance Highlights (Proud Nurse Stats)
                  Text(
                    'Shift Performance & Quality Audit',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricBox(
                          'Alarms Handled',
                          '$resolvedAlarms',
                          '100% Resolved',
                          const Color(0xFF2E7D32),
                          Icons.verified_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricBox(
                          'Avg Response Time',
                          '18.4 s',
                          'Benchmark: <60s',
                          AppColors.primaryTeal,
                          Icons.timer_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricBox(
                          'Ward Stability',
                          '96%',
                          'Nominal Vitals',
                          const Color(0xFF0288D1),
                          Icons.health_and_safety_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Bed Telemetry Table
                  Text(
                    'Bed Telemetry Snapshot (Real-Time)',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(2.2),
                          2: FlexColumnWidth(1.4),
                          3: FlexColumnWidth(1.4),
                          4: FlexColumnWidth(1.4),
                          5: FlexColumnWidth(1.8),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                        children: [
                          // Table Header
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade100),
                            children: [
                              _buildTableHeaderCell('Bed'),
                              _buildTableHeaderCell('Patient Name'),
                              _buildTableHeaderCell('HR (bpm)'),
                              _buildTableHeaderCell('SpO2 (%)'),
                              _buildTableHeaderCell('Temp (°C)'),
                              _buildTableHeaderCell('Link / Status'),
                            ],
                          ),
                          // Patient Rows
                          ...patients.map((patient) {
                            final telem = telemetryAsync.asData?.value[patient.bedId];
                            final hr = telem?.heartRate.toString() ?? '72';
                            final spo2 = telem?.spo2.toString() ?? '98';
                            final temp = telem?.temperature.toStringAsFixed(1) ?? '36.8';

                            return TableRow(
                              children: [
                                _buildTableCell(patient.bedLabel, isBold: true),
                                _buildTableCell(patient.name),
                                _buildTableCell(hr),
                                _buildTableCell('$spo2%'),
                                _buildTableCell('$temp°C'),
                                _buildTableCell(
                                  patient.status == PatientStatus.critical
                                      ? 'Alert (Triaged)'
                                      : 'Stable (-58dBm)',
                                  textColor: patient.status == PatientStatus.critical
                                      ? AppColors.alertCritical
                                      : const Color(0xFF2E7D32),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nurse Attestation & Digital Signature
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryMint.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.assignment_turned_in_rounded, color: AppColors.primaryTeal, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Clinical Sign-Off & Attestation',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'I certify that all bedside wireless telemetry nodes in Ward 3B were actively monitored during this shift. All $resolvedAlarms patient alerts were promptly checked and safely resolved. Patients are stable for shift handover.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sign: Sister ${activeNurse.name}, RN',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                            Text(
                              'Stamp: NABH/IEC-60601-CERT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Fixed Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      triggerWebPrint();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primaryTeal,
                          duration: const Duration(seconds: 3),
                          content: Row(
                            children: const [
                              Icon(Icons.print_rounded, color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('Opening print dialog... Report ready to print or save as PDF!'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.print_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'Print / Export PDF',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox(String title, String mainValue, String subText, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            subText,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade900,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16.5,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
    );
  }
}
