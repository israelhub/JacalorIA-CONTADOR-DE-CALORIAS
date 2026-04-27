import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppDashedActionButton extends StatefulWidget {
  const AppDashedActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.trailing,
    this.height = 44,
    this.borderRadius = AppRadius.md,
    this.borderColor = AppColors.homeDashedBorder,
    this.backgroundColor = AppColors.surface,
    this.labelStyle,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final double height;
  final double borderRadius;
  final Color borderColor;
  final Color backgroundColor;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry padding;

  @override
  State<AppDashedActionButton> createState() => _AppDashedActionButtonState();
}

class _AppDashedActionButtonState extends State<AppDashedActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }

    setState(() {
      _isHovered = value;
    });
  }

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lift = _isHovered || _isPressed;

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
        onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          scale: _isPressed ? 0.98 : (lift ? 1.01 : 1),
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            offset: Offset(0, lift ? -0.01 : 0),
            child: SizedBox(
              width: double.infinity,
              height: widget.height,
              child: CustomPaint(
                painter: _DashedRoundedRectPainter(
                  color: widget.borderColor,
                  strokeWidth: 1.5,
                  radius: widget.borderRadius,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                  child: Padding(
                    padding: widget.padding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        if (widget.leading != null) ...[
                          widget.leading!,
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: widget.labelStyle ??
                                AppTextStyles.homeAction.copyWith(
                                  color: AppColors.action500,
                                ),
                          ),
                        ),
                        if (widget.trailing != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          widget.trailing!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 8.0;
    const dashGap = 6.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}