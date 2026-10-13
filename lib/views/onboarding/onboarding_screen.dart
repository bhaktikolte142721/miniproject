import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/clay_button.dart';
import '../../core/utils/audio_alert_service.dart';
import '../home_shell_screen.dart';

/// Screen 1: Onboarding / Welcome Screen (Reference: Top-Left).
/// Displays 3D glossy clay heart asset with glowing pulse ring,
/// surgical canvas aesthetic, and tactile mint pill button.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final heartSize = (constraints.maxWidth * 0.60).clamp(180.0, 290.0);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Top navigation bar with soft back button pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
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
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: AppColors.textPrimary,
                                    size: 18,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryMint.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.primaryMint,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'WARD 3B',
                                            style: AppTextStyles.badgeText.copyWith(
                                              color: AppColors.primaryTeal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Centerpiece: Floating 3D Glossy Clay Heart with glowing pulse ring
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Ambient Cyan Halo Glow
                                  Container(
                                    width: heartSize * 0.9,
                                    height: heartSize * 0.9,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryMint.withValues(alpha: 0.18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryMint.withValues(alpha: 0.35),
                                          blurRadius: 50,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 3D Clay Heart Image
                                  Image.asset(
                                    'assets/images/vital_heart_3d.png',
                                    width: heartSize,
                                    height: heartSize,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // High-Contrast Typography matching reference UI
                            Text(
                              'Healthy Pulse\nSafe Ward',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.displayLarge.copyWith(
                                height: 1.15,
                                fontSize: 30,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Continuous acute telemetry & rapid response for Ward 3B. Keeping your patients safe and stable.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),

                            const Spacer(),
                            const SizedBox(height: 24),

                            // Primary Action Button: Wide Pill with Right-aligned circular arrow
                            ClayButton(
                              label: 'Get Started',
                              onPressed: () {
                                AudioAlertService().unlockAudio();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const HomeShellScreen()),
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Secondary Sign In link
                            GestureDetector(
                              onTap: () {
                                AudioAlertService().unlockAudio();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const HomeShellScreen()),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already on shift? ',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                  children: [
                                    TextSpan(
                                      text: 'Sign In',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primaryTeal,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Page Indicator Dots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryMint,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.chipInactive,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.chipInactive,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
