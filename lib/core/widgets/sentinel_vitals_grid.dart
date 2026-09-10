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
        // 2x2 Grid of Claymorphic Vitals Cards with Glowing 3D Pods
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Heart Rate
            Expanded(
              child: ClayCard(
                padding: const EdgeInsets.all(16),
                borderColor: heartRate > 100 || heartRate < 55
                    ? AppColors.alertCritical.withOpacity(0.5)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Heart Rate',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 21,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (heartRate > 100 || heartRate < 55)
                                ? AppColors.coralLight
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            heartRate > 100
                                ? 'Tachy'
                                : (heartRate < 55 ? 'Brady' : 'Sinus'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: heartRate > 100 || heartRate < 55
                                  ? AppColors.alertCritical
                                  : const Color(0xFFD32F2F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 3D Glowing Pod with Floating Transparent Heart
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFFFF0F2), Color(0xFFFFDDE2)],
                            stops: [0.35, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE53935).withOpacity(0.24),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                            const BoxShadow(
                              color: Color(0x99FFFFFF),
                              blurRadius: 8,
                              offset: Offset(-2, -2),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFFFCDD2),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/vital_heart_3d.png',
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$heartRate BPM',
                      style: AppTextStyles.telemetryMedium.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: heartRate > 100 || heartRate < 55
                            ? AppColors.alertCritical
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Norm: 60-100 BPM',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
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
                borderColor: spo2 < 92 ? AppColors.alertCritical.withOpacity(0.5) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Blood Oxygen',
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 21,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: spo2 < 92 ? AppColors.coralLight : AppColors.mintLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            spo2 < 92 ? 'Hypoxia' : 'Optimal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: spo2 < 92 ? AppColors.alertCritical : AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 3D Glowing Pod with Floating Transparent Droplet
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
                            stops: [0.35, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BFA5).withOpacity(0.24),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                            const BoxShadow(
                              color: Color(0x99FFFFFF),
                              blurRadius: 8,
                              offset: Offset(-2, -2),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF80DEEA),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/spo2_droplet_3d.png',
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$spo2%',
                          style: AppTextStyles.telemetryMedium.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: spo2 < 92 ? AppColors.alertCritical : AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SpO2',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMuted,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Norm: 95-100%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
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
                borderColor: temperature > 37.8 ? AppColors.alertCritical.withOpacity(0.5) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Temperature',
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 21,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: temperature > 37.8
                                ? AppColors.coralLight
                                : const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            temperature > 37.8 ? 'Pyrexia' : 'Normal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: temperature > 37.8
                                  ? AppColors.alertCritical
                                  : const Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 3D Glowing Pod with Floating Transparent Thermometer
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                            stops: [0.35, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFA000).withOpacity(0.24),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                            const BoxShadow(
                              color: Color(0x99FFFFFF),
                              blurRadius: 8,
                              offset: Offset(-2, -2),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFFFE082),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/thermometer_3d.png',
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${temperature.toStringAsFixed(1)}°C',
                      style: AppTextStyles.telemetryMedium.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: temperature > 37.8
                            ? AppColors.alertCritical
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${((temperature * 9 / 5) + 32).toStringAsFixed(1)}°F • MAX30205',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Card 4: Battery & Wireless Link
            Expanded(
              child: ClayCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Node Battery',
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 21,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'nRF24 OK',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 3D Glowing Pod with Floating Transparent Battery
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                            stops: [0.35, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF43A047).withOpacity(0.24),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                            const BoxShadow(
                              color: Color(0x99FFFFFF),
                              blurRadius: 8,
                              offset: Offset(-2, -2),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFA5D6A7),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/battery_3d.png',
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$batteryPercent% charged',
                      style: AppTextStyles.telemetryMedium.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: batteryPercent > 30
                            ? AppColors.alertStable
                            : AppColors.alertCritical,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '3.3V LDO • 48h Runtime',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
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
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
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
                      fontSize: 17,
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
