import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_dashed_action_button.dart';
import 'food_review_item_row.dart';

class FoodReviewAddItemButton extends StatelessWidget {
  const FoodReviewAddItemButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppDashedActionButton(
      label: 'Adicionar novo alimento',
      onTap: onTap,
      height: foodReviewControlHeight,
      labelStyle: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.action500,
        fontWeight: FontWeight.w700,
      ),
      trailing: const Icon(
        Icons.arrow_forward,
        color: AppColors.action500,
        size: 24,
      ),
    );
  }
}
