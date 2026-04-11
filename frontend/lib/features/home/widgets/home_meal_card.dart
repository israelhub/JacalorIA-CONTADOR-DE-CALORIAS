import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class HomeMealCard extends StatelessWidget {
  const HomeMealCard({
    super.key,
    required this.cardKey,
    required this.title,
    required this.description,
    required this.kcal,
    required this.time,
    required this.imageAsset,
    required this.height,
  });

  final Key cardKey;
  final String title;
  final String description;
  final String kcal;
  final String time;
  final String imageAsset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg - 2,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg - AppSpacing.xs),
        border: Border.all(color: AppColors.homeMealCardBorder),
        boxShadow: AppShadows.homeMealCard,
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.huge + AppSpacing.xs,
            height: AppSpacing.huge + AppSpacing.xs,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.brand300),
            ),
            child: Image.asset(imageAsset, fit: BoxFit.cover),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.homeMealTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs - 2),
                Text(
                  description,
                  style: AppTextStyles.homeMealSubtitle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                kcal,
                style: AppTextStyles.homeMealKcal.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs - 2),
              Text(
                time,
                style: AppTextStyles.captionStrong.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
