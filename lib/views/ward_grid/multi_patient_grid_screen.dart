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
import '../../providers/telemetry_provider.dart';
import '../../providers/ward_filter_provider.dart';
import '../patient_detail/patient_monitoring_screen.dart';

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
                      Icons.tune_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
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
                    orElse: () => {},
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

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ClayCard(
                          padding: const EdgeInsets.all(18),
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
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: isCritical
                                          ? AppColors.alertCriticalBg
                                          : AppColors.mintLight,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isCritical
                                            ? AppColors.alertCritical.withOpacity(0.3)
                                            : AppColors.cardBorder,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        patient.avatarUrl,
                                        width: 46,
                                        height: 46,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

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
                                                  fontSize: 10,
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
                                        const SizedBox(height: 4),
                                        Text(
                                          '${patient.age}y ${patient.gender} • ${patient.diagnosis}',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        // Node Wireless Signal & Battery Pill
                                        LiveSignalIndicator(
                                          rssi: node?.rssi ?? -60,
                                          batteryPercent: node?.batteryPercent ?? 90,
                                          isOnline: node?.isOnline ?? true,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Right Forward Arrow Circle (matching reference UI)
                                  Container(
                                    width: 36,
                                    height: 36,
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
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              const Divider(height: 1, color: AppColors.cardBorder),
                              const SizedBox(height: 14),

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
                                  Container(width: 1, height: 36, color: AppColors.cardBorder),
                                  // SpO2 (%)
                                  _buildVitalMetricPill(
                                    icon: Icons.water_drop_rounded,
                                    iconColor: isCritical ? AppColors.alertCritical : AppColors.primaryTeal,
                                    label: 'SpO2 Pulse',
                                    value: '${telemetry.spo2}',
                                    unit: '%',
                                    isWarning: telemetry.spo2 < 92,
                                  ),
                                  Container(width: 1, height: 36, color: AppColors.cardBorder),
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
                            ],
                          ),
                        ),
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
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
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
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isWarning ? AppColors.alertCritical : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
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
