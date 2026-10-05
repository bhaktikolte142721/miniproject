import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/clay_container.dart';
import '../../core/widgets/clay_card.dart';
import '../../models/alert_incident.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/telemetry_provider.dart';

/// Screen 6: Alert & Escalation Feed & Nurse Station Settings (Reference: Bottom-Right).
class AlertsFeedScreen extends ConsumerWidget {
  const AlertsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsStreamProvider);
    final mockService = ref.watch(mockTelemetryServiceProvider);
    final audioService = ref.watch(audioAlertServiceProvider);
    final isMutedAsync = ref.watch(isAudioMutedStreamProvider);
    final isMuted = isMutedAsync.maybeWhen(data: (v) => v, orElse: () => audioService.isMuted);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alert Feed & Station',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Mute / Unmute Alarm Button
                  GestureDetector(
                    onTap: () {
                      audioService.toggleMute();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isMuted
                            ? AppColors.alertCritical.withOpacity(0.12)
                            : AppColors.primaryMint.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMuted ? AppColors.alertCritical : AppColors.primaryMint,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            size: 16,
                            color: isMuted ? AppColors.alertCritical : AppColors.primaryTeal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isMuted ? 'Muted' : 'Alarm Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isMuted ? AppColors.alertCritical : AppColors.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Nurse Station Profile Card matching Reference UI (Top of Bottom-Right screen)
              ClayCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Profile Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.mintLight,
                        border: Border.all(color: AppColors.primaryMint, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'SJ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nurse Sarah Jenkins, RN',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lead Triage • Shift 3B-Day',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'sarah.jenkins@hospital.org',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.chipInactive,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Active Incidents Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Telemetry Alarms',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Chaos Mode / Trigger Test Alarm button
                  GestureDetector(
                    onTap: () {
                      mockService.triggerTestAlarm(
                        'bed_03',
                        'Sustained SpO2 < 87% (Clinical Desaturation)',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.alertCritical,
                          content: const Text('Simulated Critical Hypoxemia alarm dispatched!'),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.alertCritical.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+ Test Alarm',
                        style: AppTextStyles.badgeText.copyWith(
                          color: AppColors.alertCritical,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Alerts Stream View
              alertsAsync.when(
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return ClayCard(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.alertStable,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'All Bedside Nodes Nominal',
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No active threshold violations in Ward 3B.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: alerts.map((alert) {
                      final isCritical = alert.severity == AlertSeverity.critical;
                      final progress = (alert.secondsRemaining / 60.0).clamp(0.0, 1.0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: ClayCard(
                          padding: const EdgeInsets.all(16),
                          borderColor: alert.isAcknowledged
                              ? AppColors.cardBorder
                              : (isCritical ? AppColors.alertCritical : AppColors.alertWarning),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Severity tag, Bed ID, Countdown timer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isCritical
                                              ? AppColors.alertCritical
                                              : AppColors.alertWarning,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isCritical ? 'CRITICAL' : 'WARNING',
                                          style: AppTextStyles.badgeText.copyWith(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        alert.bedId.toUpperCase().replaceAll('_', ' '),
                                        style: AppTextStyles.titleSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text('• ${alert.patientName}', style: AppTextStyles.bodySmall),
                                    ],
                                  ),
                                  if (!alert.isAcknowledged)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.alertCriticalBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.timer_rounded, size: 12, color: AppColors.alertCritical),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${alert.secondsRemaining}s',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.alertCritical,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Trigger Reason
                              Text(
                                alert.triggerReason,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // 60-second Countdown Progress Bar for Auto-Escalation
                              if (!alert.isAcknowledged) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Escalation Target: ${alert.escalationStageLabel}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: isCritical ? AppColors.alertCritical : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Auto-escalates in ${alert.secondsRemaining}s',
                                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: AppColors.chipInactive,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isCritical ? AppColors.alertCritical : AppColors.alertWarning,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Action Buttons: Acknowledge & Clear
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!alert.isAcknowledged)
                                    GestureDetector(
                                      onTap: () {
                                        mockService.acknowledgeAlert(alert.id, 'Nurse Sarah');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryMint,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          'Acknowledge',
                                          style: AppTextStyles.buttonText.copyWith(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      mockService.clearAlert(alert.id);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.chipInactive,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        'Clear Alarm',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),

              const SizedBox(height: 20),

              // Station Menu Options matching Reference UI (Bottom-Right Profile settings list)
              Text(
                'Ward Console Preferences',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              ClayCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.router_rounded,
                      title: 'ESP32 Gateway Configuration',
                      subtitle: '192.168.1.142 • Port 3000 • WebSocket',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 54),
                    _buildSettingsTile(
                      icon: Icons.wifi_tethering_rounded,
                      title: 'nRF24 Node Diagnostics',
                      subtitle: '3 Active Nodes • 2.4GHz ISM Band',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 54),
                    _buildSettingsTile(
                      icon: Icons.tune_rounded,
                      title: 'Alarm Threshold Matrix',
                      subtitle: 'Clinical SpO2 / HR / Temp Triggers',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 54),
                    _buildSettingsTile(
                      icon: Icons.history_edu_rounded,
                      title: 'Shift Handover Audit Records',
                      subtitle: '28 May 2024 to Present',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 54),
                    _buildSettingsTile(
                      icon: Icons.sync_rounded,
                      title: 'Hospital EMR Sync (FHIR / HL7)',
                      subtitle: 'Connected to Epic / Cerner EHR',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.mintLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryTeal, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
        size: 22,
      ),
      onTap: onTap,
    );
  }
}
