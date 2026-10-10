import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/workout_models.dart';

class WorkoutRoutineChips extends StatelessWidget {
  const WorkoutRoutineChips({
    super.key,
    required this.routines,
    required this.selectedRoutineId,
    required this.onSelect,
    this.onAdd,
    this.onRename,
    this.onDelete,
  });

  final List<WorkoutRoutine> routines;
  final String? selectedRoutineId;
  final ValueChanged<String> onSelect;
  final VoidCallback? onAdd;
  final ValueChanged<WorkoutRoutine>? onRename;
  final ValueChanged<WorkoutRoutine>? onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: routines.length + (onAdd == null ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (onAdd != null && index == routines.length) {
            return _ChipButton(
              label: 'Novo',
              selected: false,
              icon: Icons.add,
              onTap: onAdd!,
            );
          }

          final routine = routines[index];
          final selected = routine.id == selectedRoutineId;
          return _ChipButton(
            label: routine.name,
            selected: selected,
            onTap: () => onSelect(routine.id),
            onLongPress: onRename == null && onDelete == null
                ? null
                : () => _openActions(context, routine),
          );
        },
      ),
    );
  }

  Future<void> _openActions(
    BuildContext context,
    WorkoutRoutine routine,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.name,
                  style: AppTextStyles.missionsSectionTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Renomear'),
                  onTap: () => Navigator.of(context).pop('rename'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.textError,
                  ),
                  title: Text(
                    'Apagar ficha',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textError,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop('delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'rename') {
      onRename?.call(routine);
    } else if (action == 'delete') {
      onDelete?.call(routine);
    }
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.action500 : AppColors.insetSurface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        key: ValueKey('workout-routine-chip-$label'),
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppColors.surface : AppColors.action500,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: AppTextStyles.homeAction.copyWith(
                  color: selected
                      ? AppColors.surface
                      : AppColors.brand900Variant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
