import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/clay_container.dart';
import '../../core/widgets/clay_card.dart';
import '../../core/widgets/clay_icon_box.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/nurse_provider.dart';
import '../../models/patient.dart';
import '../patient_detail/patient_monitoring_screen.dart';
import '../settings/ward_settings_sheet.dart';
import '../ward_grid/node_health_sheet.dart';
import '../reports/clinical_report_dialog.dart';

/// Screen 2: Shift Handover & Ward Home Overview (Reference: Top-Center).
class ShiftHandoverScreen extends ConsumerWidget {
  final Function(int)? onNavigateTab;

  const ShiftHandoverScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(telemetryStreamProvider);
    ref.watch(gatewayStatusStreamProvider);
    final criticalCount = ref.watch(activeCriticalAlarmsCountProvider);
    final totalAlarmsCount = ref.watch(totalActiveAlarmsCountProvider);
    final patients = ref.watch(patientsListProvider);
    final activeNurse = ref.watch(activeNurseProvider);
    final resolvedAlarms = ref.watch(resolvedAlarmsCountProvider).maybeWhen(
          data: (val) => val,
          orElse: () => ref.read(mockTelemetryServiceProvider).resolvedAlarmsCount,
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Floating Top Bar: Nurse Greeting, Settings & Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'On-Duty Nursing Station,',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                activeNurse.name,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.headlineSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('👋', style: TextStyle(fontSize: 22)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Settings Icon Button
                      GestureDetector(
                        onTap: () => WardSettingsSheet.show(context, initialTab: 1),
                        child: Container(
                          width: 42,
                          height: 42,
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
                          child: const Icon(
                            Icons.settings_rounded,
                            color: AppColors.primaryTeal,
                            size: 21,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Notification Bell with critical alert badge
                      GestureDetector(
                        onTap: () => onNavigateTab?.call(3), // Navigate to Alerts tab
                        child: Container(
                          width: 42,
                          height: 42,
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
                                size: 21,
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
                      const SizedBox(width: 10),

                      // Nurse Profile Avatar (Click to switch or register nurse)
                      GestureDetector(
                        onTap: () => WardSettingsSheet.show(context, initialTab: 0),
                        child: Container(
                          width: 42,
                          height: 42,
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
                          child: Center(
                            child: Text(
                              activeNurse.initials,
                              style: const TextStyle(
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
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
                                    fontSize: 15,
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
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 3D Vital Monitor Image Asset with Curved Corners & Layered Shadows
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/images/vital_monitor_3d.png',
                              height: 112,
                              fit: BoxFit.cover,
                            ),
                          ),
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
                    onTap: () => NodeHealthSheet.show(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 5. Vital Health Score Card matching Reference UI (Dental Health Score -> Telemetry Score)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ward Telemetry Status',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  GestureDetector(
                    onTap: () => ClinicalReportDialog.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                          const BoxShadow(
                            color: Color(0x33FFFFFF),
                            blurRadius: 4,
                            offset: Offset(-1, -1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.print_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Print Shift Report',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                                : 'All ${patients.length} patient wireless nodes transmitting nominal vitals to gateway.',
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

              const SizedBox(height: 20),

              // 5.5 Nurse Clinical Pride & Hero Recognition Card (Alarms Handled Successfully)
              _buildNursePrideCard(context, activeNurse.name, resolvedAlarms),

              const SizedBox(height: 22),

              // 6. Monitored Beds Quick Carousel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Patients (${patients.length})',
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

                      return TweenAnimationBuilder<double>(
                        key: ValueKey(patient.id),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 350),
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
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                    const BoxShadow(
                                      color: Colors.white,
                                      blurRadius: 4,
                                      offset: Offset(-1, -1),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    patient.avatarUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
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

  /// Celebratory Nurse Clinical Excellence & Alarms Handled Recognition Card
  Widget _buildNursePrideCard(BuildContext context, String nurseName, int resolvedAlarms) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D3D36),
            Color(0xFF13534B),
            Color(0xFF1B6A5F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF4DB6AC).withOpacity(0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D3D36).withOpacity(0.4),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          const BoxShadow(
            color: Color(0x33FFFFFF),
            blurRadius: 8,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Champion Badge & Recognition Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('🏆', style: TextStyle(fontSize: 15)),
                    SizedBox(width: 5),
                    Text(
                      'NURSE APPRECIATION',
                      style: TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.bolt_rounded, color: Color(0xFF80CBC4), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Quick Response',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main Center Row: 3D Shield Badge with Curved Corners + Big Proud Metric
          Row(
            children: [
              // 3D Sentinel Shield Badge with Curved Frame & Radiant Aura Shadow
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/sentinel_shield_badge_3d.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$resolvedAlarms',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Alarms Handled Successfully',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE0F2F1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All patient alerts were checked and safely attended to by $nurseName today.',
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.3,
                        color: Colors.white.withOpacity(0.88),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Uplifting Nurse Affirmation Quote & Celebration Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '“Thank you for taking good care of all patients in Ward 3B today, Sister $nurseName!”',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 15,
                      color: Color(0xFFE0F2F1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.cardSurface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        title: Row(
                          children: const [
                            Text('🎖️', style: TextStyle(fontSize: 26)),
                            SizedBox(width: 10),
                            Text('Nurse Appreciation', style: TextStyle(fontWeight: FontWeight.w800)),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sister $nurseName,',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You have answered and resolved $resolvedAlarms patient alarms during your shift today.\n\nYour quick help keeps our patients safe and comfortable. We truly appreciate your hard work and care. The whole team is thankful for you! 👏❤️',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Happy to Help ❤️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('👏', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 4),
                        Text(
                          'Say Thanks',
                          style: TextStyle(
                            color: Color(0xFF3E2723),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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
}

