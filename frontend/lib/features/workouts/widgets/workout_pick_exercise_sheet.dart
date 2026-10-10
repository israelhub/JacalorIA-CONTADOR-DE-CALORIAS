import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_modal.dart';
import '../helpers/workout_formatters.dart';
import '../models/workout_models.dart';

Future<WorkoutExercise?> showWorkoutPickExerciseSheet(
  BuildContext context, {
  required String routineName,
  required List<WorkoutExercise> remaining,
  required List<WorkoutExercise> logged,
}) {
  return showDialog<WorkoutExercise>(
    context: context,
    builder: (context) {
      return AppModal(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O que você fez',
              style: AppTextStyles.missionsSectionTitle.copyWith(
                color: AppColors.brand900Variant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              remaining.isEmpty
                  ? 'Tudo de $routineName já está no dia. Toque num exercício para mudar o peso.'
                  : 'Escolha um exercício de $routineName. Na sequência a gente pergunta o peso.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...remaining.map(
                      (exercise) => _ExerciseTile(
                        exercise: exercise,
                        done: false,
                        onTap: () => Navigator.of(context).pop(exercise),
                      ),
                    ),
                    ...logged.map(
                      (exercise) => _ExerciseTile(
                        exercise: exercise,
                        done: true,
                        onTap: () => Navigator.of(context).pop(exercise),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        exercise.name,
        style: AppTextStyles.homeMealTitle.copyWith(
          color: AppColors.brand900Variant,
        ),
      ),
      subtitle: Text(
        done
            ? 'Já no dia${last == null ? '' : ' · ${formatWorkoutWeight(last.weight)} kg'}'
            : '${exercise.sets} × ${exercise.reps}',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Icon(
        done ? Icons.check_circle_outline : Icons.add,
        color: done ? AppColors.action500 : AppColors.brand900Variant,
      ),
    );
  }
}
