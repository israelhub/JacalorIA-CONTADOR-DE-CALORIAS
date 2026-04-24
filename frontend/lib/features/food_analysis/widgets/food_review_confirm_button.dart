import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';

class FoodReviewConfirmButton extends StatelessWidget {
  const FoodReviewConfirmButton({
    super.key,
    required this.isBusy,
    required this.onTap,
  });

  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.action500,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: const [
            BoxShadow(
              color: AppColors.action500Shadow,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.surface,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      key: const ValueKey('food-review-confirm-button'),
      height: 40,
      child: AppButton(
        label: 'Confirmar',
        onPressed: onTap,
        trailingIcon: Icons.arrow_forward,
      ),
    );
  }
}
