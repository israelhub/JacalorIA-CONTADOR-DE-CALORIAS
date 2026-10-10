import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_input.dart';

final double foodReviewControlHeight = AppInputStyles.singleLineHeight;

class FoodReviewItemRow extends StatelessWidget {
  const FoodReviewItemRow({
    super.key,
    required this.index,
    required this.nameController,
    required this.measurementController,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final TextEditingController nameController;
  final TextEditingController measurementController;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AppInput(
            key: ValueKey('food-review-name-field-$index'),
            controller: nameController,
            onChanged: (_) => onChanged(),
            showBorder: true,
            showShadow: false,
            borderColor: AppColors.foodReviewFieldBorder,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          width: 76,
          child: AppInput(
            key: ValueKey('food-review-measurement-field-$index'),
            controller: measurementController,
            onChanged: (_) => onChanged(),
            showBorder: true,
            showShadow: false,
            borderColor: AppColors.foodReviewFieldBorder,
            textAlign: TextAlign.center,
            centerContent: true,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        if (onRemove != null)
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete),
            color: AppColors.foodReviewDeleteIcon,
            iconSize: 24,
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 26),
          )
        else
          const SizedBox(width: 28),
      ],
    );
  }
}
