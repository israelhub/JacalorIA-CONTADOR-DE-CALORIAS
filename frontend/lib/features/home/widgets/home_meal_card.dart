import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_skeleton.dart';

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
    required this.height,
    this.onTap,
  });

  final Key cardKey;
  final String title;
  final String description;
  final String kcal;
  final String time;
  final String? imageAsset;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg - AppSpacing.xs),
        child: Container(
          key: cardKey,
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg - 2,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.homeCardSurface,
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
                child: imageBytes != null
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : imageUrl != null
                    ? Image(
                        image: CachedNetworkImageProvider(imageUrl!),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        frameBuilder: (_, child, frame, wasSyncLoaded) {
                          if (wasSyncLoaded || frame != null) {
                            return child;
                          }
                          return const AppSkeletonBox(
                            height: double.infinity,
                            borderRadius: 0,
                          );
                        },
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: AppColors.homeMetaCardSurface,
                          child: Icon(
                            Icons.restaurant_outlined,
                            color: AppColors.action500,
                          ),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final asset = imageAsset;
                          if (asset != null) {
                            return Image.asset(asset, fit: BoxFit.cover);
                          }

                          return const ColoredBox(
                            color: AppColors.homeMetaCardSurface,
                            child: Icon(
                              Icons.restaurant_outlined,
                              color: AppColors.action500,
                            ),
                          );
                        },
                      ),
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
        ),
      ),
    );
  }
}
