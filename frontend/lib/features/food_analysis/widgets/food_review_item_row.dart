import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_input.dart';

const double foodReviewControlHeight = 44;

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
    return SizedBox(
      height: foodReviewControlHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: AppInput(
              key: ValueKey('food-review-name-field-$index'),
              controller: nameController,
              onChanged: (_) => onChanged(),
              textAlignVertical: TextAlignVertical.top,
              contentPadding: const EdgeInsets.only(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                top: 6,
                bottom: 10,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 67,
            child: AppInput(
              key: ValueKey('food-review-measurement-field-$index'),
              controller: measurementController,
              onChanged: (_) => onChanged(),
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.top,
              contentPadding: const EdgeInsets.only(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                top: 6,
                bottom: 10,
              ),
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
      ),
    );
  }
}
