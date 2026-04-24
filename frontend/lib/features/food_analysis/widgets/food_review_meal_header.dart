import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class FoodReviewMealHeader extends StatelessWidget {
  const FoodReviewMealHeader({
    super.key,
    required this.imageBytes,
    required this.title,
    required this.timeLabel,
  });

  final Uint8List? imageBytes;
  final String title;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null && imageBytes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const ValueKey('food-review-image-container'),
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.foodReviewFieldBorder),
            boxShadow: AppShadows.foodReviewField,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: hasImage
                ? Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                : const Center(
                    child: Icon(
                      Icons.restaurant,
                      color: AppColors.action500,
                      size: 56,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 28 / 24,
                letterSpacing: -0.12,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              timeLabel,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 22 / 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
