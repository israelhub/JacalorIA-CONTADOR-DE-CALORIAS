import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/framed_avatar.dart';
import '../helpers/social_group_helpers.dart';
import '../models/social_group_models.dart';

class SocialRankingItem extends StatelessWidget {
  const SocialRankingItem({
    super.key,
    required this.entry,
    this.competitionType = 'offensive',
    this.onTap,
    this.onRemove,
    this.isRemoving = false,
  });

  final SocialRankingEntry entry;
  final String competitionType;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool isRemoving;

  @override
  Widget build(BuildContext context) {
    final subtitle = entry.isLeader ? 'Líder do grupo' : entry.subtitle.trim();
    final rowColor = entry.isCurrentUser
        ? AppColors.missionsXpPill.withValues(alpha: 0.75)
        : AppColors.surface;
    final metric = socialRankingMetric(
      competitionType: competitionType,
      points: entry.points,
      streakDays: entry.streakDays,
    );

    return Material(
      color: rowColor,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.performanceTrack.withValues(alpha: 0.95),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Center(
                          child: Text(
                            '${entry.position}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.homeMealKcal.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      FramedAvatar(
                        size: 44,
                        avatarUrl: entry.avatarUrl,
                        frameId: entry.avatarFrameId,
                        fallbackText: entry.name,
                        backgroundColor: AppColors.homeProgressTrack,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              style: AppTextStyles.homeMealTitle.copyWith(
                                color: AppColors.brand900Variant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
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
                                metric.displayValue,
                                style: AppTextStyles.homeMealKcal.copyWith(
                                  color: AppColors.brand900Variant,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                metric.icon,
                                size: 12,
                                color: metric.iconColor,
                              ),
                            ],
                          ),
                          Text(
                            metric.label,
                            style: AppTextStyles.captionStrong.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (onRemove != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconButton(
                  onPressed: isRemoving ? null : onRemove,
                  tooltip: 'Excluir membro',
                  visualDensity: VisualDensity.compact,
                  icon: isRemoving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textMuted,
                          ),
                        )
                      : const Icon(
                          Icons.person_remove_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
