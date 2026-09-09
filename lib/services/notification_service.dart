import 'package:flutter/material.dart';
import '../models/alert_incident.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Clinical notification dispatch service for FCM hooks & in-app heads-up banners.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Shows an in-app 3D claymorphic heads-up banner overlay
  void showInAppAlarmBanner(
    BuildContext context, {
    required AlertIncident alert,
    required VoidCallback onAcknowledge,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: alert.severity == AlertSeverity.critical
                    ? AppColors.alertCritical
                    : AppColors.alertWarning,
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: (alert.severity == AlertSeverity.critical
                          ? AppColors.alertCritical
                          : AppColors.alertWarning)
                      .withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                const BoxShadow(
                  color: Color(0xCCFFFFFF),
                  blurRadius: 10,
                  offset: Offset(-3, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (alert.severity == AlertSeverity.critical
                            ? AppColors.alertCritical
                            : AppColors.alertWarning)
                        .withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    alert.severity == AlertSeverity.critical
                        ? Icons.warning_rounded
                        : Icons.info_outline_rounded,
                    color: alert.severity == AlertSeverity.critical
                        ? AppColors.alertCritical
                        : AppColors.alertWarning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            alert.bedId.toUpperCase().replaceAll('_', ' '),
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.alertCritical,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${alert.patientName}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.triggerReason,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    entry.remove();
                    onAcknowledge();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Ack',
                      style: AppTextStyles.buttonText.copyWith(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Auto dismiss overlay after 7 seconds if not manually tapped
    Future.delayed(const Duration(seconds: 7), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}
