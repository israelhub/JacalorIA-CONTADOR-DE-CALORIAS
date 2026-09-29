import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MacroProgressIndicator extends StatefulWidget {
  const MacroProgressIndicator({
    super.key,
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
    this.progressKey,
    this.labelStyle,
    this.valueStyle,
    this.trackColor = AppColors.homeProgressTrack,
    this.barHeight = AppSpacing.xs + 2,
  });

  final String label;
  final int consumed;
  final int goal;
  final Color color;
  final Key? progressKey;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Color trackColor;
  final double barHeight;

  @override
  State<MacroProgressIndicator> createState() => _MacroProgressIndicatorState();
}

class _MacroProgressIndicatorState extends State<MacroProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _valueAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _configureAnimations();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant MacroProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.consumed != widget.consumed || oldWidget.goal != widget.goal) {
      _configureAnimations();
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _configureAnimations() {
    final progress = widget.goal == 0
        ? 0.0
        : (widget.consumed / widget.goal).clamp(0.0, 1.0);

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _progressAnimation = curvedAnimation.drive(
      Tween<double>(begin: 0, end: progress),
    );
    _valueAnimation = curvedAnimation.drive(
      Tween<double>(begin: 0, end: widget.consumed.toDouble()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animatedConsumed = _valueAnimation.value.round();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style:
                  widget.labelStyle ??
                  AppTextStyles.captionStrong.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm / 2),
              child: SizedBox(
                height: widget.barHeight,
                child: LinearProgressIndicator(
                  key: widget.progressKey,
                  value: _progressAnimation.value,
                  backgroundColor: widget.trackColor,
                  color: widget.color,
                  minHeight: widget.barHeight,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$animatedConsumed/${widget.goal}g',
              style:
                  widget.valueStyle ??
                  AppTextStyles.micro.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}
