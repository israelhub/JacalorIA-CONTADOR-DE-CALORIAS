import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/missions_overview.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({super.key, required this.mission});

  final MissionItem mission;

  @override
  Widget build(BuildContext context) {
    final isCompleted = mission.isCompleted;
    final accentColor = switch (mission.accent) {
      MissionAccent.action => AppColors.action500,
      MissionAccent.accent => AppColors.accent500,
      MissionAccent.challenge => AppColors.missionsChallenge,
    };

    final iconBackground = switch (mission.accent) {
      MissionAccent.action => AppColors.missionsActionIconBg,
      MissionAccent.accent => AppColors.missionsAccentIconBg,
      MissionAccent.challenge => AppColors.missionsChallengeIconBg,
    };

    final iconData = switch (mission.accent) {
      MissionAccent.action => Icons.restaurant_menu_rounded,
      MissionAccent.accent => Icons.emoji_events_rounded,
      MissionAccent.challenge => Icons.auto_awesome_rounded,
    };

    final percent = mission.progressPercent.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.action500.withValues(alpha: 0.55)
              : AppColors.performanceCardBorder,
          width: 2,
        ),
        boxShadow: AppShadows.performanceCard,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, size: 20, color: accentColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        mission.title,
                        style: AppTextStyles.missionsCardTitle.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.missionsXpPill,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.action500.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Completada',
                          style: AppTextStyles.missionsProgress.copyWith(
                            color: AppColors.action500Shadow,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mission.description,
                  style: AppTextStyles.missionsCardDescription.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        mission.progressLabel,
                        style: AppTextStyles.missionsProgress.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: AppTextStyles.missionsProgress.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: AppSpacing.sm,
                    color: accentColor,
                    backgroundColor: AppColors.performanceTrack,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 14,
                      color: AppColors.accent500,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '+${mission.rewardGold}',
                      style: AppTextStyles.missionsRewardGold,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: AppColors.action500,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '+${mission.rewardXp} XP',
                      style: AppTextStyles.missionsRewardXp,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
