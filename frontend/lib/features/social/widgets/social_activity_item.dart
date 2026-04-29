import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../helpers/social_group_helpers.dart';
import '../models/social_group_models.dart';

class SocialActivityItemWidget extends StatelessWidget {
  const SocialActivityItemWidget({super.key, required this.activity});

  final SocialActivityItem activity;

  @override
  Widget build(BuildContext context) {
    final isHighlighted =
        activity.activityType == 'created' ||
        activity.message.toLowerCase().contains('você');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.missionsXpPill : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isHighlighted
              ? AppColors.action500.withValues(alpha: 0.6)
              : AppColors.performanceCardBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? AppColors.action500.withValues(alpha: 0.14)
                  : AppColors.homeProgressTrack,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Icon(
              isHighlighted
                  ? Icons.auto_awesome_rounded
                  : Icons.notifications_active_outlined,
              size: 16,
              color: isHighlighted ? AppColors.action500 : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.brand900Variant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  socialRelativeTimeLabel(activity.createdAt),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}