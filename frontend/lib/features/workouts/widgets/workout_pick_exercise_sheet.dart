import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../helpers/workout_formatters.dart';
import '../models/workout_models.dart';
import 'workout_exercise_card.dart';

Future<WorkoutExercise?> showWorkoutPickExerciseSheet(
  BuildContext context, {
  required List<WorkoutExercise> remaining,
  required List<WorkoutExercise> logged,
}) {
  return showModalBottomSheet<WorkoutExercise>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      return Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'O que você fez',
                  style: AppTextStyles.missionsSectionTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < remaining.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(height: AppSpacing.sm),
                          _ExercisePickCard(
                            exercise: remaining[index],
                            done: false,
                            onTap: () =>
                                Navigator.of(context).pop(remaining[index]),
                          ),
                        ],
                        for (var index = 0; index < logged.length; index++) ...[
                          if (index > 0 || remaining.isNotEmpty)
                            const SizedBox(height: AppSpacing.sm),
                          _ExercisePickCard(
                            exercise: logged[index],
                            done: true,
                            onTap: () =>
                                Navigator.of(context).pop(logged[index]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ExercisePickCard extends StatelessWidget {
  const _ExercisePickCard({
    required this.exercise,
    required this.done,
    required this.onTap,
  });

  final WorkoutExercise exercise;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = exercise.lastLoad;
    final radius = BorderRadius.circular(WorkoutExerciseCard.radius);
    final subtitle = done
        ? 'Já no dia${last == null ? '' : ' · ${formatWorkoutWeight(last.weight)} kg'}'
        : '${exercise.sets} × ${exercise.reps}${last == null ? '' : ' · ${formatWorkoutWeight(last.weight)} kg'}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: WorkoutExerciseCard.height,
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.insetSurface,
            borderRadius: radius,
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
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                done ? Icons.check_circle_outline : Icons.add_rounded,
                color: done ? AppColors.action500 : AppColors.brand900Variant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
