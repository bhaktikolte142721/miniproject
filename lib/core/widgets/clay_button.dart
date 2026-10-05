import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Pill-shaped tactile 3D claymorphic button matching the exact reference UI style.
/// Features vibrant mint/teal gradient, soft drop shadow, and circular arrow icon.
class ClayButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showArrow;
  final IconData? customIcon;
  final Gradient? gradient;
  final Color? solidColor;
  final Color textColor;
  final double height;
  final double? width;
  final EdgeInsetsGeometry padding;

  const ClayButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.showArrow = true,
    this.customIcon,
    this.gradient,
    this.solidColor,
    this.textColor = AppColors.textOnDark,
    this.height = 54,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    final effectiveGradient = widget.gradient ??
        (widget.solidColor == null ? AppColors.heroCardGradient : null);

    return AnimatedScale(
      scale: _isDown ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutBack,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isDown = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isDown = false) : null,
        onTapCancel: isEnabled ? (_) => setState(() => _isDown = false) : null,
        onTap: isEnabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: effectiveGradient,
            color: effectiveGradient == null ? (widget.solidColor ?? AppColors.primaryMint) : null,
            boxShadow: [
              BoxShadow(
                color: (widget.solidColor ?? AppColors.primaryMint).withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: Color(0x66FFFFFF),
                blurRadius: 6,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else ...[
                Text(
                  widget.label,
                  style: AppTextStyles.buttonText.copyWith(color: widget.textColor),
                ),
                if (widget.showArrow || widget.customIcon != null) ...[
                  const Spacer(),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.customIcon ?? Icons.arrow_forward_rounded,
                      color: widget.textColor,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
