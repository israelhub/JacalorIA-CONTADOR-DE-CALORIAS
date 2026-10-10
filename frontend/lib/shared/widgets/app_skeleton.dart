import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSkeletonBox extends StatefulWidget {
  const AppSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadius.md,
    this.color,
    this.highlightColor,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;
  final Color? highlightColor;

  @override
  State<AppSkeletonBox> createState() => _AppSkeletonBoxState();
}

class _AppSkeletonBoxState extends State<AppSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final color = Color.lerp(
          widget.color ?? AppColors.skeleton,
          widget.highlightColor ?? AppColors.skeletonHighlight,
          _controller.value,
        );

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 72,
    this.gap = AppSpacing.md,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.pageHorizontal,
      vertical: AppSpacing.lg,
    ),
    this.borderRadius = AppRadius.md,
  });

  final int itemCount;
  final double itemHeight;
  final double gap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          for (var index = 0; index < itemCount; index += 1) ...[
            if (index > 0) SizedBox(height: gap),
            AppSkeletonBox(height: itemHeight, borderRadius: borderRadius),
          ],
        ],
      ),
    );
  }
}

class AppSkeletonFriendRow extends StatelessWidget {
  const AppSkeletonFriendRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AppSkeletonBox(width: 52, height: 52, borderRadius: AppRadius.pill),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBox(height: 16, width: 140),
              SizedBox(height: AppSpacing.sm),
              AppSkeletonBox(height: 12, width: 88),
            ],
          ),
        ),
      ],
    );
  }
}
