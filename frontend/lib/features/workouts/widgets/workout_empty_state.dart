import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';

class WorkoutEmptyState extends StatelessWidget {
  const WorkoutEmptyState({super.key, required this.onCreateRoutine});

  final VoidCallback onCreateRoutine;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.missionsActionIconBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.fitness_center,
            color: AppColors.action500,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Seus treinos, do seu jeito',
          textAlign: TextAlign.center,
          style: AppTextStyles.missionsSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Monte o Treino A, B, C ou o nome que quiser. O peso de cada exercício você anota na Home.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Criar meu primeiro treino',
          onPressed: onCreateRoutine,
        ),
      ],
    );
  }
}
