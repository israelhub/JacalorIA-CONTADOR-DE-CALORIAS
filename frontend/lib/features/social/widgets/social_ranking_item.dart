import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/social_group_models.dart';

class SocialRankingItem extends StatelessWidget {
  const SocialRankingItem({super.key, required this.entry});

  final SocialRankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final rowColor = entry.isCurrentUser
      ? AppColors.missionsXpPill.withValues(alpha: 0.75)
        : AppColors.surface;

    final topAccent = entry.position == 1
        ? AppColors.accent500
        : entry.position == 2
        ? AppColors.missionsRewardGold
        : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          bottom: BorderSide(
            color: AppColors.performanceTrack.withValues(alpha: 0.95),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Icon(Icons.emoji_events_rounded, size: 20, color: topAccent),
          ),
          const SizedBox(width: AppSpacing.xs),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.homeProgressTrack,
            backgroundImage:
                entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                ? NetworkImage(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null || entry.avatarUrl!.isEmpty
                ? Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: AppTextStyles.captionStrong.copyWith(
                      color: AppColors.brand900Variant,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        style: AppTextStyles.homeMealTitle.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isCurrentUser) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.action500,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'VOCÊ',
                          style: AppTextStyles.captionStrong.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ] else if (entry.isLeader) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 12,
                        color: AppColors.accent500,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.subtitle,
                  style: AppTextStyles.captionStrong.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    '${entry.points}',
                    style: AppTextStyles.homeMealKcal.copyWith(
                      color: AppColors.brand900Variant,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 12,
                    color: AppColors.missionsRewardGold,
                  ),
                ],
              ),
              Text(
                'Sequência',
                style: AppTextStyles.captionStrong.copyWith(
                  color: AppColors.textSecondary,
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
