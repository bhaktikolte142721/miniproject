import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/clay_container.dart';
import '../../core/widgets/clay_card.dart';
import '../../core/widgets/clay_pill_chip.dart';
import '../../core/widgets/live_signal_indicator.dart';
import '../../models/patient.dart';
import '../../models/telemetry_data.dart';
import '../../models/node_status.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/ward_filter_provider.dart';
import '../patient_detail/patient_monitoring_screen.dart';
import '../patients/patient_admission_sheet.dart';
import '../settings/ward_settings_sheet.dart';

/// Screen 3: Multi-Patient Ward Grid & Telemetry Cards (Reference: Top-Right).
class MultiPatientGridScreen extends ConsumerWidget {
  const MultiPatientGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(patientsListProvider);
    final telemetryAsync = ref.watch(telemetryStreamProvider);
    final nodesAsync = ref.watch(nodeStatusStreamProvider);
    final selectedFilter = ref.watch(wardFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Ward 3B Telemetry',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => PatientAdmissionSheet.show(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Admit',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => WardSettingsSheet.show(context, initialTab: 1),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorder, width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.primaryTeal,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar Pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: ClayContainer(
                height: 46,
                borderRadius: BorderRadius.circular(23),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search patient vitals...',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Filter Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: WardFilter.values.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClayPillChip(
                      label: filter.label,
                      isSelected: selectedFilter == filter,
                      onTap: () {
                        ref.read(wardFilterProvider.notifier).state = filter;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Patient Grid Cards List
            Expanded(
              child: telemetryAsync.when(
                data: (telemetryMap) {
                  final nodesMap = nodesAsync.maybeWhen(
                    data: (map) => map,
                    orElse: () => <String, NodeStatus>{},
                  );

                  // Apply filter
                  final filteredPatients = patients.where((patient) {
                    final data = telemetryMap[patient.bedId];
                    switch (selectedFilter) {
                      case WardFilter.all:
                        return true;
                      case WardFilter.bed01:
                        return patient.bedId == 'bed_01';
                      case WardFilter.bed02:
                        return patient.bedId == 'bed_02';
                      case WardFilter.bed03:
                        return patient.bedId == 'bed_03';
                      case WardFilter.highRisk:
                        return data?.status == PatientStatus.critical;
                      case WardFilter.batteryLow:
                        final node = nodesMap[patient.bedId];
                        return (node?.batteryPercent ?? 100) < 80;
                      case WardFilter.disconnected:
                        final node = nodesMap[patient.bedId];
                        return !(node?.isOnline ?? true);
                    }
                  }).toList();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 850;
                      if (isWide) {
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 580,
                            mainAxisExtent: 285,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredPatients.length,
                          itemBuilder: (context, index) {
                            return _buildPatientCard(
                              context,
                              ref,
                              filteredPatients[index],
                              telemetryMap,
                              nodesMap,
                              index,
                              isGrid: true,
                            );
                          },
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          return _buildPatientCard(
                            context,
                            ref,
                            filteredPatients[index],
                            telemetryMap,
                            nodesMap,
                            index,
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading telemetry: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(
    BuildContext context,
    WidgetRef ref,
    Patient patient,
    Map<String, TelemetryData> telemetryMap,
    Map<String, NodeStatus> nodesMap,
    int index, {
    bool isGrid = false,
  }) {
    final telemetry = telemetryMap[patient.bedId] ??
        TelemetryData(
          bedId: patient.bedId,
          heartRate: 72,
          spo2: 99,
          temperature: 36.8,
          respiratoryRate: 16,
          bloodPressureSys: 120,
          bloodPressureDia: 80,
          timestamp: DateTime.now(),
        );
    final node = nodesMap[patient.bedId];
    final isCritical = telemetry.status == PatientStatus.critical;
    final isChecking = telemetry.status == PatientStatus.checking;

    return TweenAnimationBuilder<double>(
      key: ValueKey(patient.id),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (index * 60).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 14),
        child: ClayCard(
          padding: const EdgeInsets.all(16),
          borderColor: isCritical
              ? AppColors.alertCritical
              : (isChecking ? AppColors.alertWarning : null),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PatientMonitoringScreen(patient: patient),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header: 3D Thumbnail, Bed & Patient Info, Status Badge & Arrow
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3D Medical Component Thumbnail
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isCritical
                          ? AppColors.alertCriticalBg
                          : AppColors.mintLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCritical
                            ? AppColors.alertCritical.withValues(alpha: 0.3)
                            : AppColors.cardBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        patient.avatarUrl,
                        width: 42,
                        height: 42,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Patient Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isCritical
                                    ? AppColors.alertCritical
                                    : (isChecking
                                        ? AppColors.alertWarning
                                        : AppColors.primaryMint),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                patient.bedLabel,
                                style: AppTextStyles.badgeText.copyWith(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                patient.name,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${patient.age}y ${patient.gender} • ${patient.diagnosis}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 15.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        // Node Wireless Signal & Battery Pill
                        LiveSignalIndicator(
                          rssi: node?.rssi ?? -60,
                          batteryPercent: node?.batteryPercent ?? 90,
                          isOnline: node?.isOnline ?? true,
                        ),
                      ],
                    ),
                  ),

                  // Right Forward Arrow Circle
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCritical
                          ? AppColors.alertCritical
                          : AppColors.primaryMint,
                      boxShadow: [
                        BoxShadow(
                          color: (isCritical
                                  ? AppColors.alertCritical
                                  : AppColors.primaryMint)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 10),

              // Real-time Numeric Telemetry Triplet (HR, SpO2, Temp)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Heart Rate (BPM)
                  _buildVitalMetricPill(
                    icon: Icons.favorite_rounded,
                    iconColor: isCritical ? AppColors.alertCritical : Colors.redAccent,
                    label: 'Heart Rate',
                    value: '${telemetry.heartRate}',
                    unit: 'BPM',
                    isWarning: telemetry.heartRate > 100 || telemetry.heartRate < 55,
                  ),
                  Container(width: 1, height: 32, color: AppColors.cardBorder),
                  // SpO2 (%)
                  _buildVitalMetricPill(
                    icon: Icons.water_drop_rounded,
                    iconColor: isCritical ? AppColors.alertCritical : AppColors.primaryTeal,
                    label: 'SpO2 Pulse',
                    value: '${telemetry.spo2}',
                    unit: '%',
                    isWarning: telemetry.spo2 < 92,
                  ),
                  Container(width: 1, height: 32, color: AppColors.cardBorder),
                  // Temperature (°C)
                  _buildVitalMetricPill(
                    icon: Icons.thermostat_rounded,
                    iconColor: isCritical ? AppColors.alertCritical : const Color(0xFFFF9800),
                    label: 'Temp Body',
                    value: telemetry.temperature.toStringAsFixed(1),
                    unit: '°C',
                    isWarning: telemetry.temperature > 37.8,
                  ),
                ],
              ),

              // ─── Discharge Button ────────────────────────
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Admitted ${_daysAgo(patient.admissionDate)}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 14, color: AppColors.textMuted),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Row(
                            children: [
                              const Icon(Icons.logout_rounded, color: AppColors.alertCritical, size: 22),
                              const SizedBox(width: 10),
                              Text('Discharge Patient?', style: AppTextStyles.titleSmall),
                            ],
                          ),
                          content: Text(
                            'Discharge ${patient.name} from ${patient.bedLabel}?\nThis will remove their monitoring feed.',
                            style: AppTextStyles.bodyMedium,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                ref.read(patientsProvider.notifier).dischargePatient(patient.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${patient.name} discharged', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    backgroundColor: AppColors.alertWarning,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.alertCritical,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Discharge', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.alertCriticalBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.alertCritical.withValues(alpha: 0.35), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.logout_rounded, size: 15, color: AppColors.alertCritical),
                          const SizedBox(width: 5),
                          Text('Discharge', style: AppTextStyles.bodySmall.copyWith(color: AppColors.alertCritical, fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _daysAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  Widget _buildVitalMetricPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    bool isWarning = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.telemetryMedium.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isWarning ? AppColors.alertCritical : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
