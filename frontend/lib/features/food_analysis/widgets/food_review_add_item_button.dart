import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import 'food_review_item_row.dart';

class FoodReviewAddItemButton extends StatelessWidget {
  const FoodReviewAddItemButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg - AppSpacing.xs);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('food-review-add-item-button'),
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: foodReviewControlHeight + AppSpacing.sm,
          decoration: BoxDecoration(
            color: AppColors.insetSurface,
            borderRadius: radius,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                size: 22,
                color: AppColors.action500,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'Adicionar novo alimento',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.homeAction.copyWith(
                    color: AppColors.action500,
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
