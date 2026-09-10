import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Top App Brand Badge with Concentric Ripple Waves matching the reference image.
class SentinelBrandHeader extends StatelessWidget {
  const SentinelBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Concentric Cyan Ripple Rings
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryMint.withOpacity(0.18),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryMint.withOpacity(0.32),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryMint.withOpacity(0.12),
              ),
            ),

            // 3D Sentinel Shield Badge Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/sentinel_shield_badge_3d.png',
                width: 78,
                height: 78,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'SENTINEL-Ward',
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
