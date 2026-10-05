import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/clay_container.dart';
import '../../core/widgets/clay_card.dart';
import '../../core/widgets/clay_button.dart';
import '../../core/widgets/ecg_sweep_painter.dart';
import '../../core/widgets/sentinel_vitals_grid.dart';
import '../../models/patient.dart';
import '../../models/telemetry_data.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/alerts_provider.dart';

/// Screen 5: Detailed Patient Monitoring & Waveform View (Reference: Bottom-Center).
class PatientMonitoringScreen extends ConsumerStatefulWidget {
  final Patient patient;

  const PatientMonitoringScreen({super.key, required this.patient});

  @override
  ConsumerState<PatientMonitoringScreen> createState() => _PatientMonitoringScreenState();
}

class _PatientMonitoringScreenState extends ConsumerState<PatientMonitoringScreen> {
  int _selectedTab = 0; // 0: Overview, 1: Live ECG Waveform, 2: 15m Trends

  @override
  Widget build(BuildContext context) {
    final telemetryAsync = ref.watch(telemetryStreamProvider);
    final mockService = ref.watch(mockTelemetryServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${widget.patient.bedLabel} • ${widget.patient.name}',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'ID: ${widget.patient.id} • ${widget.patient.diagnosis}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
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
                        Icons.more_horiz_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              // Segmented Subtabs Pill (Overview, Live ECG, Trends)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.chipInactive,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _buildSubTabItem('Overview', 0),
                      _buildSubTabItem('Live ECG', 1),
                      _buildSubTabItem('15m Trends', 2),
                    ],
                  ),
                ),
              ),

              // Tab Body Content
              Expanded(
                child: telemetryAsync.when(
                  data: (telemetryMap) {
                    final telemetry = telemetryMap[widget.patient.bedId] ??
                        TelemetryData(
                          bedId: widget.patient.bedId,
                          heartRate: 72,
                          spo2: 99,
                          temperature: 36.8,
                          respiratoryRate: 16,
                          bloodPressureSys: 120,
                          bloodPressureDia: 80,
                          timestamp: DateTime.now(),
                        );
                    final isCritical = telemetry.status == PatientStatus.critical;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        children: [
                          if (_selectedTab == 0) ...[
                            // 1. Centerpiece: 3D Glossy Organ Asset with glowing halo
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 190,
                                  height: 190,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (isCritical
                                            ? AppColors.alertCritical
                                            : AppColors.primaryMint)
                                        .withOpacity(0.12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isCritical
                                                ? AppColors.alertCritical
                                                : AppColors.primaryMint)
                                            .withOpacity(0.25),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                Image.asset(
                                  widget.patient.avatarUrl,
                                  width: 170,
                                  height: 170,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Overall Status Bar matching Reference UI
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Overall Status',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        isCritical ? 'Critical (74%)' : 'Optimal (98%)',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isCritical
                                              ? AppColors.alertCritical
                                              : AppColors.primaryTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: isCritical ? 0.74 : 0.98,
                                      minHeight: 10,
                                      backgroundColor: AppColors.chipInactive,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isCritical
                                            ? AppColors.alertCritical
                                            : AppColors.primaryMint,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 2x2 3D Claymorphic Telemetry Grid & Call Nurse Pill
                            SentinelVitalsGrid(
                              heartRate: telemetry.heartRate,
                              spo2: telemetry.spo2,
                              temperature: telemetry.temperature,
                              batteryPercent: 92,
                              onCallNurse: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.cardSurface,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    title: Row(
                                      children: const [
                                        Text('🚨', style: TextStyle(fontSize: 22)),
                                        SizedBox(width: 10),
                                        Text('Nurse Call Dispatched'),
                                      ],
                                    ),
                                    content: Text(
                                      'Emergency bedside call alert transmitted to Nurse Sarah Jenkins for ${widget.patient.bedLabel} (${widget.patient.name}).',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: const Text('Dismiss', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                          ] else if (_selectedTab == 1) ...[
                            // 2. Real-time ECG Sweep Line Waveform
                            const Text(
                              'Live Hospital Monitor Rhythm (Lead II)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            EcgSweepView(
                              height: 180,
                              traceColor: isCritical ? AppColors.alertCritical : AppColors.primaryMint,
                              speed: isCritical ? 0.4 : 0.25,
                            ),
                            const SizedBox(height: 16),
                            ClayCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.speed_rounded, color: AppColors.primaryTeal),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('ECG Sweep Rate: 50 mm/s', style: AppTextStyles.titleSmall),
                                        Text(
                                          'Sinus Rhythm • Filter: 0.5 - 40 Hz • Notch: 50Hz',
                                          style: AppTextStyles.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // 3. 15-Minute Historical Trend Charts (fl_chart)
                            const Text(
                              '15-Minute Telemetry Trend Trends',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 200,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (val) => FlLine(
                                      color: AppColors.chipInactive,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: const FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: telemetry.recentBpmHistory
                                          .asMap()
                                          .entries
                                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                                          .toList(),
                                      isCurved: true,
                                      color: isCritical ? AppColors.alertCritical : AppColors.primaryMint,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: (isCritical ? AppColors.alertCritical : AppColors.primaryMint)
                                            .withOpacity(0.15),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Bottom Primary Action: View Full Report / Acknowledge
                          ClayButton(
                            label: isCritical ? 'Acknowledge Vitals Alarm' : 'View Full Telemetry Report',
                            solidColor: isCritical ? AppColors.alertCritical : null,
                            onPressed: () {
                              if (isCritical) {
                                mockService.acknowledgeAlert(
                                  'ALT-${widget.patient.bedId}',
                                  'Nurse Sarah',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.alertStable,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    content: const Text('Alarm acknowledged. Logged to shift audit trail.'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.primaryTeal,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    content: const Text('Full Telemetry Dossier Exported to Ward EMR.'),
                                  ),
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Telemetry error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: const [
                  Icon(Icons.phone_in_talk_rounded, color: AppColors.primaryMint),
                  SizedBox(width: 10),
                  Text('Station Intercom'),
                ],
              ),
              content: Text(
                'Connecting live audio link to Bedside Node for ${widget.patient.name} (${widget.patient.bedLabel})...',
                style: AppTextStyles.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primaryMint,
                        content: Text('Intercom channel opened with ${widget.patient.bedLabel}.'),
                      ),
                    );
                  },
                  child: const Text('Open Channel', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
        label: const Text('Direct Call Node', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSubTabItem(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailMetricTile({
    required String label,
    required String value,
    required String unit,
    required String status,
    required Color color,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
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
      child: Column(
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.telemetryMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeRow(String label, String normalRange, String current, bool isViolation) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            Text('Target: $normalRange', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        Text(
          current,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isViolation ? AppColors.alertCritical : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
