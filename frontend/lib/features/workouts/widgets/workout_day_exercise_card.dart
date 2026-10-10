import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../home/widgets/home_meal_card.dart';
import '../helpers/workout_formatters.dart';
import '../helpers/workout_day_helpers.dart';

class WorkoutDayExerciseCard extends StatelessWidget {
  const WorkoutDayExerciseCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
    this.backgroundColor = AppColors.homeCardSurface,
  });

  final WorkoutDayEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Color backgroundColor;

  static const height = HomeMealCard.defaultHeight;
  static const _imagePadding = HomeMealCard.imagePadding;
  static const _iconSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg - AppSpacing.xs);
    final imageSize = height - (_imagePadding * 2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: radius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(_imagePadding),
                child: SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: const Center(
                    child: Icon(
                      Icons.fitness_center,
                      size: _iconSize,
                      color: AppColors.action500,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg - 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              entry.exercise.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.homeMealTitle.copyWith(
                                color: AppColors.brand900Variant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs - 2),
                            Text(
                              '${entry.routine.name} · ${entry.exercise.sets} × ${entry.exercise.reps}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.homeMealSubtitle.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${formatWorkoutWeight(entry.load.weight)} kg',
                        style: AppTextStyles.homeMealKcal.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
