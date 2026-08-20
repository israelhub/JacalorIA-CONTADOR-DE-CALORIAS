import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_anchored_menu.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../models/social_group_models.dart';
import '../widgets/social_empty_state.dart';
import '../widgets/social_ranking_item.dart';

class SocialRankingTabPage extends StatelessWidget {
  const SocialRankingTabPage({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    required this.ranking,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onOpenProfile,
  });

  final SocialXpRankingPeriod period;
  final ValueChanged<SocialXpRankingPeriod> onPeriodChanged;
  final List<SocialRankingEntry> ranking;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<SocialRankingEntry> onOpenProfile;

  static const _periods = <SocialXpRankingPeriod>[
    SocialXpRankingPeriod.all,
    SocialXpRankingPeriod.month,
    SocialXpRankingPeriod.week,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Ranking de XP',
          titleStyle: AppTextStyles.missionsSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
          trailing: _PeriodFilterDropdown(
            period: period,
            periods: _periods,
            onChanged: onPeriodChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isLoading && ranking.isEmpty)
          const _RankingSkeleton()
        else if (errorMessage != null && ranking.isEmpty)
          _RankingError(message: errorMessage!, onRetry: onRetry)
        else if (ranking.isEmpty)
          const SocialEmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Ninguém no ranking ainda',
            subtitle: 'Complete missões para acumular XP e aparecer aqui.',
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.performanceCardBorder,
                width: 2,
              ),
              boxShadow: AppShadows.performanceCard,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Stack(
                children: [
                  Column(
                    children: [
                      for (final entry in ranking)
                        SocialRankingItem(
                          entry: entry,
                          competitionType: 'xp',
                          onTap: entry.userId.trim().isEmpty
                              ? null
                              : () => onOpenProfile(entry),
                        ),
                    ],
                  ),
                  if (isLoading)
                    Positioned.fill(
                      child: ColoredBox(
                        color: AppColors.surface.withValues(alpha: 0.45),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.action500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PeriodFilterDropdown extends StatelessWidget {
  const _PeriodFilterDropdown({
    required this.period,
    required this.periods,
    required this.onChanged,
  });

  final SocialXpRankingPeriod period;
  final List<SocialXpRankingPeriod> periods;
  final ValueChanged<SocialXpRankingPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppAnchoredMenu(
      childBuilder: (context, {required isOpen, required toggle}) {
        return GestureDetector(
          key: const ValueKey('xp-ranking-period-filter'),
          onTap: toggle,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                period.label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.brand900Variant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.brand900Variant,
                ),
              ),
            ],
          ),
        );
      },
      menuBuilder: (context, {required close}) {
        return _PeriodFilterMenu(
          period: period,
          periods: periods,
          onSelected: (selected) async {
            await close();
            if (selected == period) return;
            onChanged(selected);
          },
        );
      },
    );
  }
}

class _PeriodFilterMenu extends StatelessWidget {
  const _PeriodFilterMenu({
    required this.period,
    required this.periods,
    required this.onSelected,
  });

  final SocialXpRankingPeriod period;
  final List<SocialXpRankingPeriod> periods;
  final ValueChanged<SocialXpRankingPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.performanceCardBorder, width: 2),
          boxShadow: AppShadows.performanceCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md - 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < periods.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.performanceTrack,
                  ),
                _PeriodFilterMenuItem(
                  label: periods[i].label,
                  selected: periods[i] == period,
                  onTap: () => onSelected(periods[i]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodFilterMenuItem extends StatelessWidget {
  const _PeriodFilterMenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.brand900Variant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.action500,
              ),
          ],
        ),
      ),
    );
  }
}

class _RankingSkeleton extends StatelessWidget {
  const _RankingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.performanceCardBorder, width: 2),
      ),
      child: const Column(
        children: [
          _RankingRowSkeleton(),
          _RankingRowSkeleton(),
          _RankingRowSkeleton(),
        ],
      ),
    );
  }
}

class _RankingRowSkeleton extends StatelessWidget {
  const _RankingRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.performanceTrack.withValues(alpha: 0.95),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: const Row(
        children: [
          SizedBox(
            width: 28,
            child: Center(child: AppSkeletonBox(height: 14, width: 16)),
          ),
          SizedBox(width: AppSpacing.xs),
          AppSkeletonBox(width: 44, height: 44, borderRadius: AppRadius.pill),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSkeletonBox(height: 16, width: 120),
                SizedBox(height: 6),
                AppSkeletonBox(height: 12, width: 72),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSkeletonBox(height: 16, width: 40),
              SizedBox(height: 4),
              AppSkeletonBox(height: 12, width: 28),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankingError extends StatelessWidget {
  const _RankingError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(label: 'Tentar novamente', onPressed: onRetry),
      ],
    );
  }
}
