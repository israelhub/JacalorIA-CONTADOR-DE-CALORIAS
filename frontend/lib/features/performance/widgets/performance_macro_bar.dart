import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class PerformanceMacroBar extends StatelessWidget {
  const PerformanceMacroBar({
    super.key,
    required this.label,
    required this.percent,
    required this.fillColor,
  });

  final String label;
  final int percent;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percent.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.performanceMacroLabel.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Text(
              '$clampedPercent% da meta',
              style: AppTextStyles.performanceMacroLabel.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: AppSpacing.sm,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const ColoredBox(color: AppColors.performanceTrack),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: clampedPercent / 100,
                  child: ColoredBox(color: fillColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
