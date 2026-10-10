import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../workouts/models/workout_models.dart';

enum HomeAddChoice { meal, workout }

Future<HomeAddChoice?> showHomeAddChoiceSheet(BuildContext context) {
  return showDialog<HomeAddChoice>(
    context: context,
    builder: (context) {
      return AppModal(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O que você quer adicionar?',
              style: AppTextStyles.missionsSectionTitle.copyWith(
                color: AppColors.brand900Variant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.restaurant_outlined,
                color: AppColors.action500,
              ),
              title: const Text('Refeição'),
              onTap: () => Navigator.of(context).pop(HomeAddChoice.meal),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.fitness_center,
                color: AppColors.action500,
              ),
              title: const Text('Treino'),
              onTap: () => Navigator.of(context).pop(HomeAddChoice.workout),
            ),
          ],
        ),
      );
    },
  );
}

Future<WorkoutRoutine?> showHomeWorkoutRoutineSheet(
  BuildContext context, {
  required List<WorkoutRoutine> routines,
}) {
  if (routines.isEmpty) {
    return Future<WorkoutRoutine?>.value();
  }
  if (routines.length == 1) {
    return Future<WorkoutRoutine?>.value(routines.first);
  }

  return showDialog<WorkoutRoutine>(
    context: context,
    builder: (context) {
      return AppModal(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Qual ficha?',
              style: AppTextStyles.missionsSectionTitle.copyWith(
                color: AppColors.brand900Variant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...routines.map(
              (routine) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(routine.name),
                subtitle: Text(
                  routine.exercises.isEmpty
                      ? 'Sem exercícios'
                      : '${routine.exercises.length} exercício${routine.exercises.length == 1 ? '' : 's'}',
                ),
                onTap: () => Navigator.of(context).pop(routine),
              ),
            ),
          ],
        ),
      );
    },
  );
}
