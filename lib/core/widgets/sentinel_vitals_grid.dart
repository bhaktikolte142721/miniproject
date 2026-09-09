import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'clay_card.dart';

/// 2x2 Telemetry Grid and Call Nurse Pill matching the exact reference UI image.
class SentinelVitalsGrid extends StatelessWidget {
  final int heartRate;
  final int spo2;
  final double temperature;
  final int batteryPercent;
  final VoidCallback onCallNurse;

  const SentinelVitalsGrid({
    super.key,
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.batteryPercent,
    required this.onCallNurse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 2x2 Grid of Claymorphic Vitals Cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Heart Rate
            Expanded(
              child: ClayCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heart Rate',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Image.asset(
                        'assets/images/heart_ecg_strip_3d.png',
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$heartRate BPM',
                      style: AppTextStyles.telemetryMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: heartRate > 100 || heartRate < 55
                            ? AppColors.alertCritical
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Card 2: Blood Oxygen (SpO2)
            Expanded(
              child: ClayCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blood Oxygen (SpO2)',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Image.asset(
                        'assets/images/spo2_droplet_3d.png',
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$spo2%',
                          style: AppTextStyles.telemetryMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: spo2 < 92 ? AppColors.alertCritical : AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SpO2',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 3: Body Temperature
            Expanded(
              child: ClayCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Body Temperature',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Image.asset(
                        'assets/images/thermometer_3d.png',
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${temperature.toStringAsFixed(1)}°C',
                      style: AppTextStyles.telemetryMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: temperature > 37.8
                            ? AppColors.alertCritical
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Card 4: Battery Level
            Expanded(
              child: ClayCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Battery Level',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Image.asset(
                        'assets/images/battery_3d.png',
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$batteryPercent% charged',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: batteryPercent > 30
                            ? AppColors.alertStable
                            : AppColors.alertCritical,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Floating 3D "CALL NURSE" Pill Button matching reference image
        GestureDetector(
          onTap: onCallNurse,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF80CBC4).withOpacity(0.35),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF4DB6AC).withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMint.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                const BoxShadow(
                  color: Color(0x80FFFFFF),
                  blurRadius: 8,
                  offset: Offset(-2, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nurse Avatar Circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.primaryMint, width: 1.5),
                  ),
                  child: const Center(
                    child: Text('👩‍⚕️', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 10),

                // Orange/Coral Pill Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFFF5252)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40FF5252),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'CALL NURSE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Ringing Bell Icon with sound ripples
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Text('🔔', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
