import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../helpers/workout_formatters.dart';
import '../models/workout_models.dart';

class WorkoutExerciseCard extends StatelessWidget {
  const WorkoutExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  final WorkoutExercise exercise;
  final VoidCallback onTap;

  static const height = AppSpacing.huge + AppSpacing.xl + AppSpacing.sm;
  static const radius = AppRadius.lg - AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final last = exercise.lastLoad;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.insetSurface,
            borderRadius: BorderRadius.circular(radius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.homeMealTitle.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _MetaTag(
                            label: '${exercise.sets} × ${exercise.reps}',
                            backgroundColor: AppColors.missionsXpPill,
                            foregroundColor: AppColors.action500,
                          ),
                          if (last != null)
                            _MetaTag(
                              label: '${formatWorkoutWeight(last.weight)} kg',
                              backgroundColor: AppColors.missionsGoldPill,
                              foregroundColor: AppColors.missionsRewardGold,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionStrong.copyWith(color: foregroundColor),
      ),
    );
  }
}
