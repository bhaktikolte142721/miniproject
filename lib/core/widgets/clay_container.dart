import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 3D Claymorphic Container implementing soft directional lighting,
/// rounded borders, and subtle inner borders.
class ClayContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color color;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? customShadows;
  final VoidCallback? onTap;
  final bool isPressed;

  const ClayContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color = AppColors.cardSurface,
    this.gradient,
    this.border,
    this.customShadows,
    this.onTap,
    this.isPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(24);
    final shadows = customShadows ??
        (isPressed
            ? AppColors.pressedClayShadows
            : AppColors.standardClayShadows);

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: effectiveRadius,
        border: border ?? Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
