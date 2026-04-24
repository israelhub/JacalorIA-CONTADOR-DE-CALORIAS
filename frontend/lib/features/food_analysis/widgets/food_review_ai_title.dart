import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class FoodReviewAiTitle extends StatelessWidget {
  const FoodReviewAiTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        key: const ValueKey('food-review-ai-title-inline'),
        spacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Alimentos identificados pela IA',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.auto_awesome, color: AppColors.accent500, size: 22),
        ],
      ),
    );
  }
}
