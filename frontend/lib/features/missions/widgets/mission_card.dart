import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../models/missions_overview.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({super.key, required this.mission, this.onTap});

  final MissionItem mission;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = mission.isCompleted;
    final accentColor = switch (mission.accent) {
      MissionAccent.action => AppColors.action500,
      MissionAccent.accent => AppColors.accent500,
      MissionAccent.challenge => AppColors.missionsChallenge,
    };

    final percent = mission.progressPercent.clamp(0, 100);
    const barHeight = 22.0;

    final card = Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? Color.alphaBlend(
                accentColor.withValues(alpha: 0.10),
                AppColors.surface,
              )
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? accentColor.withValues(alpha: 0.28)
              : AppColors.performanceCardBorder,
          width: 1.5,
        ),
        boxShadow: AppShadows.performanceCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  mission.title,
                  style: AppTextStyles.missionsCardTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
              ),
              if (isCompleted) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.check_circle_rounded, size: 22, color: accentColor),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: SizedBox(
                    height: barHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        ColoredBox(
                          color: isCompleted
                              ? accentColor.withValues(alpha: 0.18)
                              : AppColors.performanceTrack,
                        ),
                        FractionallySizedBox(
                          widthFactor: percent / 100,
                          alignment: Alignment.centerLeft,
                          child: ColoredBox(color: accentColor),
                        ),
                        Center(
                          child: Text(
                            mission.progressLabel,
                            style: AppTextStyles.missionsProgress.copyWith(
                              color: percent >= 45
                                  ? AppColors.surface
                                  : AppColors.brand900Variant,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                child: Row(
                  children: <Widget>[
                    const AppSvgIcon.gold(size: 16),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        '+${mission.rewardGold}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.missionsRewardGold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 52,
                child: Row(
                  children: <Widget>[
                    const AppSvgIcon.xp(size: 16),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        '+${mission.rewardXp}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.missionsRewardXp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
