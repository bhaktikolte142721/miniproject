import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 3D Claymorphic Icon Box for quick action tiles with smooth hover lift & glow.
class ClayIconBox extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final String? badgeCount;

  const ClayIconBox({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = AppColors.primaryMint,
    this.backgroundColor = AppColors.cardSurface,
    this.onTap,
    this.badgeCount,
  });

  @override
  State<ClayIconBox> createState() => _ClayIconBoxState();
}

class _ClayIconBoxState extends State<ClayIconBox> {
  bool _isHovered = false;
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _isDown = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isDown = false) : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isDown = false) : null,
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isDown ? 0.94 : (_isHovered ? 1.06 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _isHovered
                            ? widget.iconColor.withValues(alpha: 0.8)
                            : AppColors.cardBorder,
                        width: _isHovered ? 1.6 : 1.2,
                      ),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: widget.iconColor.withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                              const BoxShadow(
                                color: Color(0xD9FFFFFF),
                                blurRadius: 10,
                                offset: Offset(-3, -3),
                              ),
                            ]
                          : const [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Color(0xD9FFFFFF),
                                blurRadius: 8,
                                offset: Offset(-3, -3),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 26,
                      ),
                    ),
                  ),
                  if (widget.badgeCount != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.alertCritical,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          widget.badgeCount!,
                          style: AppTextStyles.badgeText.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: _isHovered ? FontWeight.w800 : FontWeight.w600,
                  color: _isHovered ? widget.iconColor : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
