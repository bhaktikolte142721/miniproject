import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'clay_container.dart';

/// Frosted pearl claymorphic card with smooth 60fps hover lift,
/// dynamic soft glowing shadow, and animated tap response.
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(24);

    final standardShadows = const [
      BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 6)),
      BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 12, offset: Offset(-4, -4)),
    ];

    final hoverShadows = [
      const BoxShadow(color: Color(0x18000000), blurRadius: 26, offset: Offset(0, 12)),
      BoxShadow(
        color: AppColors.primaryMint.withValues(alpha: 0.18),
        blurRadius: 18,
        offset: const Offset(0, 4),
      ),
      const BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 12, offset: Offset(-4, -4)),
    ];

    final pressedShadows = const [
      BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: _isDown ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutQuad,
        child: AnimatedSlide(
          offset: Offset(0, _isHovered && !_isDown ? -0.015 : 0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            onTapDown: widget.onTap != null ? (_) => setState(() => _isDown = true) : null,
            onTapUp: widget.onTap != null ? (_) => setState(() => _isDown = false) : null,
            onTapCancel: widget.onTap != null ? () => setState(() => _isDown = false) : null,
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
              customShadows: _isDown
                  ? pressedShadows
                  : (_isHovered ? hoverShadows : standardShadows),
              border: Border.all(
                color: _isHovered
                    ? AppColors.primaryMint.withValues(alpha: 0.7)
                    : (widget.borderColor ?? AppColors.cardBorder),
                width: _isHovered ? 1.6 : 1.4,
              ),
              isPressed: _isDown,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
