import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/clay_container.dart';
import '../../core/widgets/clay_card.dart';
import '../../core/widgets/clay_icon_box.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/alerts_provider.dart';
import '../patient_detail/patient_monitoring_screen.dart';

/// Screen 2: Shift Handover & Ward Home Overview (Reference: Top-Center).
class ShiftHandoverScreen extends ConsumerWidget {
  final Function(int)? onNavigateTab;

  const ShiftHandoverScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(telemetryStreamProvider);
    final gatewayAsync = ref.watch(gatewayStatusStreamProvider);
    final criticalCount = ref.watch(activeCriticalAlarmsCountProvider);
    final totalAlarmsCount = ref.watch(totalActiveAlarmsCountProvider);
    final patients = ref.watch(patientsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Floating Top Bar: Nurse Greeting & Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning,',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Nurse Sarah',
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('👋', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Notification Bell with critical alert badge
                      GestureDetector(
                        onTap: () => onNavigateTab?.call(3), // Navigate to Alerts tab
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder, width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Color(0xD9FFFFFF),
                                blurRadius: 8,
                                offset: Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                criticalCount > 0
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_none_rounded,
                                color: criticalCount > 0
                                    ? AppColors.alertCritical
                                    : AppColors.textPrimary,
                                size: 22,
                              ),
                              if (totalAlarmsCount > 0)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.alertCritical,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nurse Profile Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.mintLight,
                          border: Border.all(color: AppColors.primaryMint, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A00BFA5),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'SJ',
                            style: TextStyle(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. Soft Claymorphic Search Pill
              ClayContainer(
                height: 50,
                borderRadius: BorderRadius.circular(25),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search patient, doctor, bed...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Teal Gradient Hero Card (Next Rounds & Gateway Status)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.heroCardGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryMint.withOpacity(0.38),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                    const BoxShadow(
                      color: Color(0x4DFFFFFF),
                      blurRadius: 8,
                      offset: Offset(-2, -2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'ESP32 Gateway: Online',
                                  style: AppTextStyles.badgeText.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Ward 3B Telemetry',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '3 Nodes Synchronized • Acute Care',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => onNavigateTab?.call(1), // Go to Ward Grid
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1F000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                'View Live Grid',
                                style: AppTextStyles.buttonText.copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 3D Vital Monitor Image Asset
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Image.asset(
                          'assets/images/vital_monitor_3d.png',
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Quick Actions Row (4 Claymorphic round tiles matching reference UI)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ClayIconBox(
                    icon: Icons.calendar_month_rounded,
                    label: 'Rounds',
                    iconColor: AppColors.primaryMint,
                    onTap: () => onNavigateTab?.call(2), // Shift Handover Calendar
                  ),
                  ClayIconBox(
                    icon: Icons.grid_view_rounded,
                    label: 'Ward Grid',
                    iconColor: AppColors.primaryTeal,
                    onTap: () => onNavigateTab?.call(1), // Live Grid
                  ),
                  ClayIconBox(
                    icon: Icons.warning_amber_rounded,
                    label: 'Alarms Feed',
                    iconColor: AppColors.alertCritical,
                    badgeCount: criticalCount > 0 ? '$criticalCount' : null,
                    onTap: () => onNavigateTab?.call(3), // Alerts
                  ),
                  ClayIconBox(
                    icon: Icons.medical_services_rounded,
                    label: 'Node Health',
                    iconColor: const Color(0xFF0288D1),
                    onTap: () => onNavigateTab?.call(1),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 5. Vital Health Score Card matching Reference UI (Dental Health Score -> Telemetry Score)
              Text(
                'Ward Telemetry Status',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              ClayCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    // Circular Stability Gauge (e.g. 96%)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: CircularProgressIndicator(
                            value: criticalCount > 0 ? 0.72 : 0.96,
                            strokeWidth: 7,
                            backgroundColor: AppColors.chipInactive,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              criticalCount > 0
                                  ? AppColors.alertCritical
                                  : AppColors.primaryMint,
                            ),
                          ),
                        ),
                        Text(
                          criticalCount > 0 ? '72%' : '96%',
                          style: AppTextStyles.telemetrySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: criticalCount > 0
                                ? AppColors.alertCritical
                                : AppColors.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            criticalCount > 0 ? 'Action Required!' : 'Ward Stable!',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: criticalCount > 0
                                  ? AppColors.alertCritical
                                  : AppColors.primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            criticalCount > 0
                                ? '$criticalCount critical telemetry alert requires nurse bedside check.'
                                : 'All 3 patient wireless nodes transmitting nominal vitals to gateway.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 6. Monitored Beds Quick Carousel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Patients (3)',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  GestureDetector(
                    onTap: () => onNavigateTab?.call(1),
                    child: Text(
                      'See All >',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick Preview Cards for Beds 1, 2, 3
              telemetryAsync.when(
                data: (telemetryMap) {
                  return Column(
                    children: patients.map((patient) {
                      final data = telemetryMap[patient.bedId];
                      final isCrit = data?.status == PatientStatus.critical;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ClayCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          borderColor: isCrit ? AppColors.alertCritical : null,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PatientMonitoringScreen(patient: patient),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Image.asset(
                                patient.avatarUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          patient.bedLabel,
                                          style: AppTextStyles.titleSmall.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '• ${patient.name}',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'HR: ${data?.heartRate ?? "--"} bpm | SpO2: ${data?.spo2 ?? "--"}% | ${data?.temperature ?? "--"}°C',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: isCrit ? AppColors.alertCritical : AppColors.textSecondary,
                                        fontWeight: isCrit ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCrit
                                      ? AppColors.alertCritical.withOpacity(0.12)
                                      : AppColors.primaryMint.withOpacity(0.12),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: isCrit ? AppColors.alertCritical : AppColors.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
