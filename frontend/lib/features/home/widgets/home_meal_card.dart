import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/faded_meal_image.dart';

class HomeMealCard extends StatelessWidget {
  const HomeMealCard({
    super.key,
    required this.cardKey,
    required this.title,
    required this.description,
    required this.kcal,
    required this.time,
    this.imageAsset,
    this.imageBytes,
    this.imageUrl,
    this.height = defaultHeight,
    this.backgroundColor = AppColors.homeCardSurface,
    this.onTap,
  });

  static const double defaultHeight =
      AppSpacing.huge + AppSpacing.xl + AppSpacing.sm;
  static const double imagePadding = AppSpacing.sm;

  final Key cardKey;
  final String title;
  final String description;
  final String kcal;
  final String time;
  final String? imageAsset;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final double height;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg - AppSpacing.xs);
    final imageSize = height - (imagePadding * 2);
    final hasImage = hasFadedMealImage(
      imageAsset: imageAsset,
      imageBytes: imageBytes,
      imageUrl: imageUrl,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          key: cardKey,
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: radius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(imagePadding),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: hasImage
                        ? FadedMealImage(
                            imageAsset: imageAsset,
                            imageBytes: imageBytes,
                            imageUrl: imageUrl,
                          )
                        : const MealImageFallback(),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg - 2),
                  child: Row(
                    children: [
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
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs - 2),
                            Text(
                              description,
                              style: AppTextStyles.homeMealSubtitle.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              softWrap: false,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
