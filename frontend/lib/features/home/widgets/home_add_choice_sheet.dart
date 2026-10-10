import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../workouts/models/workout_models.dart';
import '../../workouts/widgets/workout_exercise_card.dart';

enum HomeAddChoice { meal, workout }

Future<HomeAddChoice?> showHomeAddChoiceSheet(BuildContext context) {
  return showModalBottomSheet<HomeAddChoice>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      return _HomeChoiceSheet(
        title: 'O que você quer adicionar?',
        children: [
          _SheetOptionCard(
            title: 'Refeição',
            leading: Icons.restaurant_outlined,
            onTap: () => Navigator.of(context).pop(HomeAddChoice.meal),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SheetOptionCard(
            title: 'Treino',
            leading: Icons.fitness_center,
            onTap: () => Navigator.of(context).pop(HomeAddChoice.workout),
          ),
        ],
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

  return showModalBottomSheet<WorkoutRoutine>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      return _HomeChoiceSheet(
        title: 'Qual ficha?',
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < routines.length; index++) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.sm),
                    _SheetOptionCard(
                      title: routines[index].name,
                      subtitle: routines[index].exercises.isEmpty
                          ? 'Sem exercícios'
                          : '${routines[index].exercises.length} exercício${routines[index].exercises.length == 1 ? '' : 's'}',
                      leading: Icons.fitness_center,
                      onTap: () => Navigator.of(context).pop(routines[index]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _HomeChoiceSheet extends StatelessWidget {
  const _HomeChoiceSheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
                title,
                style: AppTextStyles.missionsSectionTitle.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOptionCard extends StatelessWidget {
  const _SheetOptionCard({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final IconData? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(WorkoutExerciseCard.radius);

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
              if (leading != null) ...[
                Icon(leading, color: AppColors.action500, size: 22),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.homeMealTitle.copyWith(
                        color: AppColors.brand900Variant,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
    );
  }
}
