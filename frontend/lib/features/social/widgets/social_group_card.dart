import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../helpers/social_group_helpers.dart';
import '../models/social_group_models.dart';

class SocialGroupCard extends StatelessWidget {
  const SocialGroupCard({
    super.key,
    required this.group,
    this.isFinished = false,
    this.onTap,
  });

  final SocialGroupSummary group;
  final bool isFinished;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.performanceCardBorder,
              width: 2,
            ),
            boxShadow: AppShadows.performanceCard,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: socialIconBackgroundColor(),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      socialGroupIconData(group.iconKey),
                      size: 26,
                      color: AppColors.action500,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: AppTextStyles.homeMealTitle.copyWith(
                                  color: AppColors.brand900Variant,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                        if (group.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            group.description,
                            style: AppTextStyles.homeMealSubtitle.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _InfoPill(
                              icon: Icons.people_alt_outlined,
                              label: '${group.memberCount}',
                              color: AppColors.textMuted,
                            ),
                            _InfoPill(
                              icon: Icons.emoji_events_outlined,
                              label: group.competitionLabel,
                              color: AppColors.textMuted,
                            ),
                            _InfoPill(
                              icon: Icons.timer_outlined,
                              label: group.durationDaysLabel,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Divider(
                color: AppColors.performanceTrack.withValues(alpha: 0.9),
                height: 1,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    size: 12,
                    color: AppColors.accent500,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Posição ${group.rankPosition}º',
                    style: AppTextStyles.captionStrong.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    isFinished && group.competitionType != 'group_streak'
                        ? 'Grupo finalizado'
                        : group.remainingDaysLabel,
                    style: AppTextStyles.captionStrong.copyWith(
                      color: isFinished ? AppColors.textError : AppColors.missionsRewardGold,
                      fontWeight: FontWeight.w700,
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: AppTextStyles.captionStrong.copyWith(
            color: color,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
