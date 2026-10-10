import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../helpers/home_steps_helpers.dart';
import '../models/home_steps_models.dart';

class HomeStepsCard extends StatelessWidget {
  const HomeStepsCard({
    super.key,
    required this.overview,
    this.onActivate,
    this.onEditGoal,
    this.isLoading = false,
  });

  final HomeStepsOverview overview;
  final VoidCallback? onActivate;
  final VoidCallback? onEditGoal;
  final bool isLoading;

  static const double cardHeight = 168;
  static const _mascotAsset = 'assets/images/jaca_steps.jpg';

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    final showAction = overview.canRequestAccess && onActivate != null;

    return Container(
      key: const ValueKey('home-steps-card'),
      width: double.infinity,
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.homeStepsGradientStart,
            AppColors.homeStepsGradientEnd,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeStepsShadow,
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.45,
              child: Align(
                alignment: const Alignment(-2.6, 1.35),
                child: FractionallySizedBox(
                  widthFactor: 0.78,
                  heightFactor: 0.95,
                  child: Image.asset(
                    _mascotAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.homeStepsGradientStart.withValues(alpha: 0.28),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  key: const ValueKey('home-steps-goal-edit'),
                  onTap: onEditGoal,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Row(
                    children: [
                      ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          AppColors.surface,
                          BlendMode.srcIn,
                        ),
                        child: Text(
                          '👣',
                          style: AppTextStyles.homeSectionTitle.copyWith(
                            fontSize: 16,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Passos',
                          style: AppTextStyles.homeSectionTitle.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                      if (onEditGoal != null)
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppColors.surface.withValues(alpha: 0.9),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: Center(
                    child: _StepsRing(
                      remaining: overview.remainingSteps,
                      progress: overview.remainingProgress,
                      isLoading: isLoading,
                    ),
                  ),
                ),
                if (showAction)
                  _ActivateButton(onPressed: onActivate!)
                else if (overview.status == HomeStepsStatus.ready)
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
                  )
                else
                  Text(
                    overview.status == HomeStepsStatus.unsupported
                        ? 'Disponível no app mobile.'
                        : homeStepsStatusMessage(overview),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.micro.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.82),
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

class _StepsRing extends StatelessWidget {
  const _StepsRing({
    required this.remaining,
    required this.progress,
    required this.isLoading,
  });

  final int remaining;
  final double progress;
  final bool isLoading;

  static const double size = 96;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _StepsRingPainter(fraction: isLoading ? 0 : progress),
          ),
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.surface,
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatStepsCount(remaining),
                  key: const ValueKey('home-steps-ring-value'),
                  style: AppTextStyles.statValue.copyWith(
                    color: AppColors.surface,
                    fontSize: remaining >= 10000 ? 18 : 22,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'restantes',
                  style: AppTextStyles.micro.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
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
        color: AppColors.surface.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.surface),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.micro.copyWith(
                color: AppColors.surface,
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
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.homeStepsGradientEnd,
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

class _StepsRingPainter extends CustomPainter {
  _StepsRingPainter({required this.fraction});

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          AppColors.brand300,
          AppColors.surface,
          AppColors.brand300.withValues(alpha: 0.85),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    final sweep = math.pi * 2 * fraction.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StepsRingPainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }
}
