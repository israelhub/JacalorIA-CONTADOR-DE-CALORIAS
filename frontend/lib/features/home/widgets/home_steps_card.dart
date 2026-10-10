import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../shared/theme/app_theme.dart';
import '../helpers/home_steps_helpers.dart';
import '../models/home_steps_models.dart';
import 'home_water_card.dart';

class HomeStepsCard extends StatelessWidget {
  const HomeStepsCard({
    super.key,
    required this.overview,
    this.onActivate,
    this.onOpenDetails,
    this.isLoading = false,
    this.expanded = false,
  });

  final HomeStepsOverview overview;
  final VoidCallback? onActivate;
  final VoidCallback? onOpenDetails;
  final bool isLoading;
  final bool expanded;

  static const double cardHeight = HomeWaterCard.cardHeight + AppSpacing.xl;
  static const Color _accent = AppColors.action500;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    final showAction = overview.canRequestAccess && onActivate != null;
    final showMetrics =
        expanded && !showAction && overview.status == HomeStepsStatus.ready;

    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        expanded ? AppSpacing.lg : AppSpacing.md,
        AppSpacing.lg,
        expanded ? AppSpacing.lg : AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: expanded ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (!expanded) ...[
            Text(
              'Passos',
              style: AppTextStyles.homeSectionTitle.copyWith(
                color: AppColors.brand900Variant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (expanded)
            _StepsBody(
              remaining: overview.remainingSteps,
              steps: overview.steps,
              goalSteps: overview.goalSteps,
              isLoading: isLoading,
              showRatioAsPrimary: true,
            )
          else
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _StepsBody(
                    remaining: overview.remainingSteps,
                    steps: overview.steps,
                    goalSteps: overview.goalSteps,
                    isLoading: isLoading,
                  ),
                ),
              ),
            ),
          if (showAction) ...[
            const SizedBox(height: AppSpacing.xs),
            _ActivateButton(onPressed: onActivate!),
          ] else if (showMetrics) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _MetricChip(
                    icon: Icons.local_fire_department_rounded,
                    label: formatStepsCalories(overview.caloriesKcal),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _MetricChip(
                    icon: Icons.straighten_rounded,
                    label: formatStepsDistanceKm(overview.distanceKm),
                  ),
                ),
              ],
            ),
          ] else if (expanded) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              overview.status == HomeStepsStatus.unsupported
                  ? 'Disponível no app mobile.'
                  : homeStepsStatusMessage(overview),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.micro.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _StepsProgressTrack(
            progress: overview.progress,
            isLoading: isLoading,
          ),
        ],
      ),
    );

    return Material(
      color: AppColors.homeCardSurface,
      borderRadius: radius,
      child: InkWell(
        key: const ValueKey('home-steps-open'),
        onTap: onOpenDetails,
        borderRadius: radius,
        child: SizedBox(
          key: const ValueKey('home-steps-card'),
          width: double.infinity,
          height: expanded ? null : cardHeight,
          child: content,
        ),
      ),
    );
  }
}

class _StepsBody extends StatelessWidget {
  const _StepsBody({
    required this.remaining,
    required this.steps,
    required this.goalSteps,
    required this.isLoading,
    this.showRatioAsPrimary = false,
  });

  final int remaining;
  final int steps;
  final int goalSteps;
  final bool isLoading;
  final bool showRatioAsPrimary;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: HomeStepsCard._accent,
        ),
      );
    }

    if (showRatioAsPrimary) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            formatStepsCount(steps),
            key: const ValueKey('home-steps-ring-value'),
            style: AppTextStyles.statValue.copyWith(
              color: AppColors.brand900Variant,
              fontSize: steps >= 10000 ? 28 : 36,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Flexible(
            child: Text(
              ' / ${formatStepsCount(goalSteps)} passos',
              key: const ValueKey('home-steps-ratio'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatStepsCount(remaining),
          key: const ValueKey('home-steps-ring-value'),
          textAlign: TextAlign.center,
          style: AppTextStyles.statValue.copyWith(
            color: AppColors.brand900Variant,
            fontSize: remaining >= 10000 ? 24 : 32,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'passos restantes',
          key: const ValueKey('home-steps-subtitle'),
          textAlign: TextAlign.center,
          style: AppTextStyles.micro.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StepsProgressTrack extends StatelessWidget {
  const _StepsProgressTrack({
    required this.progress,
    required this.isLoading,
  });

  final double progress;
  final bool isLoading;

  static const double _shoeSize = 22;
  static const double _barHeight = 8;

  @override
  Widget build(BuildContext context) {
    final t = isLoading ? 0.0 : progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final travel =
            (constraints.maxWidth - _shoeSize).clamp(0.0, double.infinity);
        final shoeLeft = travel * t;

        return SizedBox(
          height: _shoeSize + 4,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: SizedBox(
                    height: _barHeight,
                    width: double.infinity,
                    child: LinearProgressIndicator(
                      value: t,
                      backgroundColor: AppColors.homeProgressTrack,
                      color: HomeStepsCard._accent,
                      minHeight: _barHeight,
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: shoeLeft,
                bottom: _barHeight - 2,
                child: Icon(
                  PhosphorIcons.sneaker(PhosphorIconsStyle.fill),
                  size: _shoeSize,
                  color: HomeStepsCard._accent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.insetSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: HomeStepsCard._accent),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.micro.copyWith(
                color: AppColors.brand900Variant,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivateButton extends StatelessWidget {
  const _ActivateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        key: const ValueKey('home-steps-activate'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: HomeStepsCard._accent,
          foregroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
        ),
        child: const Text('Ativar'),
      ),
    );
  }
}
