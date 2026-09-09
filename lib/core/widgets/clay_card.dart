import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'clay_container.dart';

/// Frosted pearl claymorphic card with optional animated tap response
/// and custom status accent border.
class ClayCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Color backgroundColor;
  final Gradient? gradient;

  const ClayCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor = AppColors.cardSurface,
    this.gradient,
  });

  @override
  State<ClayCard> createState() => _ClayCardState();
}

class _ClayCardState extends State<ClayCard> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(24);

    return AnimatedScale(
      scale: _isDown ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutQuad,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _isDown = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isDown = false) : null,
        onTapCancel: widget.onTap != null ? (_) => setState(() => _isDown = false) : null,
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ClayContainer(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          margin: widget.margin,
          borderRadius: effectiveRadius,
          color: widget.backgroundColor,
          gradient: widget.gradient,
          border: Border.all(
            color: widget.borderColor ?? AppColors.cardBorder,
            width: 1.4,
          ),
          isPressed: _isDown,
          child: widget.child,
        ),
      ),
    );
  }
}
