import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_ambient_page_glow.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../widgets/home_steps_card.dart';

enum HomeCardFocusOption {
  current,
  radialScrim,
  lowerMascotOpacity,
  strongerOverlay,
  strongerTextShadow,
  valuePill,
}

class HomeStepsWeightFocusLabPage extends StatelessWidget {
  const HomeStepsWeightFocusLabPage({super.key});

  static const _options = <({HomeCardFocusOption option, String title, String blurb})>[
    (
      option: HomeCardFocusOption.current,
      title: '1. Atual',
      blurb: 'Baseline: jaca 0.45 + overlay 0.28 + sombra leve no número.',
    ),
    (
      option: HomeCardFocusOption.radialScrim,
      title: '2. Scrim radial no centro',
      blurb: 'Mancha suave na cor do card atrás do valor. Jaca segue visível nas bordas.',
    ),
    (
      option: HomeCardFocusOption.lowerMascotOpacity,
      title: '3. Jaca mais transparente',
      blurb: 'Opacidade da arte em 0.28. Simples, mas some mais o personagem.',
    ),
    (
      option: HomeCardFocusOption.strongerOverlay,
      title: '4. Overlay uniforme mais forte',
      blurb: 'Véu 0.48 no card inteiro. Melhora leitura, achata a arte.',
    ),
    (
      option: HomeCardFocusOption.strongerTextShadow,
      title: '5. Sombra do texto mais forte',
      blurb: 'Só reforça o número. Barato, efeito limitado.',
    ),
    (
      option: HomeCardFocusOption.valuePill,
      title: '6. Pill atrás do valor',
      blurb: 'Fundo arredondado semitransparente no número. Mais “UI”, mais contraste.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topInset = AppBackPageHeader.contentTopInset(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: const AppBackPageHeader(title: 'Lab foco (temp)'),
      body: AppAmbientPageBody(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            topInset + AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Text(
              'Compare as opções nos cards. Escolhe uma e me fala o número.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final item in _options) ...[
              Text(item.title, style: AppTextStyles.homeSectionTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.blurb,
                style: AppTextStyles.micro.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _FocusLabPair(option: item.option),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }
}

class _FocusLabPair extends StatelessWidget {
  const _FocusLabPair({required this.option});

  final HomeCardFocusOption option;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _FocusLabStepsCard(option: option),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _FocusLabWeightCard(option: option),
        ),
      ],
    );
  }
}

class _FocusLabStepsCard extends StatelessWidget {
  const _FocusLabStepsCard({required this.option});

  final HomeCardFocusOption option;

  @override
  Widget build(BuildContext context) {
    final cfg = _FocusConfig.from(option);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Container(
      height: HomeStepsCard.cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: AppColors.homeStepsGradientStart,
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
              opacity: cfg.mascotOpacity,
              child: Align(
                alignment: const Alignment(-2.6, 1.35),
                child: FractionallySizedBox(
                  widthFactor: 0.78,
                  heightFactor: 0.95,
                  child: Image.asset(
                    'assets/images/jaca_steps.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.homeStepsGradientStart.withValues(
                alpha: cfg.overlayAlpha,
              ),
            ),
          ),
          if (cfg.radialScrim)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.05),
                      radius: 0.72,
                      colors: [
                        AppColors.homeStepsGradientStart.withValues(alpha: 0.72),
                        AppColors.homeStepsGradientStart.withValues(alpha: 0.22),
                        AppColors.homeStepsGradientStart.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.55, 1],
                    ),
                  ),
                ),
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
                Row(
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
                    Text(
                      'Passos',
                      style: AppTextStyles.homeSectionTitle.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: Center(
                    child: _LabStepsRing(
                      remaining: 3420,
                      progress: 0.66,
                      textShadows: cfg.textShadows,
                      valuePill: cfg.valuePill,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _LabMetricChip(
                        icon: Icons.local_fire_department_rounded,
                        label: '128 kcal',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _LabMetricChip(
                        icon: Icons.straighten_rounded,
                        label: '2,4 km',
                      ),
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

class _FocusLabWeightCard extends StatelessWidget {
  const _FocusLabWeightCard({required this.option});

  final HomeCardFocusOption option;

  @override
  Widget build(BuildContext context) {
    final cfg = _FocusConfig.from(option);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Container(
      height: HomeStepsCard.cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.homeWeightGradientStart,
            AppColors.homeWeightGradientEnd,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeWeightShadow,
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: cfg.mascotOpacity,
              child: Align(
                alignment: const Alignment(2.6, 1.9),
                child: FractionallySizedBox(
                  widthFactor: 0.78,
                  heightFactor: 0.95,
                  child: Image.asset(
                    'assets/images/jaca_weight.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.homeWeightGradientStart.withValues(
                      alpha: cfg.overlayAlpha + 0.14,
                    ),
                    AppColors.homeWeightGradientEnd.withValues(
                      alpha: cfg.overlayAlpha + 0.3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (cfg.radialScrim)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.05),
                      radius: 0.72,
                      colors: [
                        AppColors.homeWeightGradientEnd.withValues(alpha: 0.72),
                        AppColors.homeWeightGradientEnd.withValues(alpha: 0.22),
                        AppColors.homeWeightGradientEnd.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.55, 1],
                    ),
                  ),
                ),
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
                Row(
                  children: [
                    Icon(
                      Icons.monitor_weight_outlined,
                      size: 18,
                      color: AppColors.surface.withValues(alpha: 0.95),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Peso',
                      style: AppTextStyles.homeSectionTitle.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: Center(
                    child: _LabWeightValue(
                      label: '78,4',
                      unit: 'kg',
                      textShadows: cfg.textShadows,
                      valuePill: cfg.valuePill,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: AppColors.surface,
                    shape: const CircleBorder(),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.add_rounded,
                        color: AppColors.homeWeightGradientEnd,
                        size: 24,
                      ),
                    ),
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

class _FocusConfig {
  const _FocusConfig({
    required this.mascotOpacity,
    required this.overlayAlpha,
    required this.radialScrim,
    required this.textShadows,
    required this.valuePill,
  });

  final double mascotOpacity;
  final double overlayAlpha;
  final bool radialScrim;
  final List<Shadow> textShadows;
  final bool valuePill;

  static const _baseShadows = <Shadow>[
    Shadow(
      color: Color(0x66000000),
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
  ];

  static const _strongShadows = <Shadow>[
    Shadow(
      color: Color(0x99000000),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
    Shadow(
      color: Color(0x55000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  factory _FocusConfig.from(HomeCardFocusOption option) {
    switch (option) {
      case HomeCardFocusOption.current:
        return const _FocusConfig(
          mascotOpacity: 0.45,
          overlayAlpha: 0.28,
          radialScrim: false,
          textShadows: _baseShadows,
          valuePill: false,
        );
      case HomeCardFocusOption.radialScrim:
        return const _FocusConfig(
          mascotOpacity: 0.45,
          overlayAlpha: 0.18,
          radialScrim: true,
          textShadows: _baseShadows,
          valuePill: false,
        );
      case HomeCardFocusOption.lowerMascotOpacity:
        return const _FocusConfig(
          mascotOpacity: 0.28,
          overlayAlpha: 0.28,
          radialScrim: false,
          textShadows: _baseShadows,
          valuePill: false,
        );
      case HomeCardFocusOption.strongerOverlay:
        return const _FocusConfig(
          mascotOpacity: 0.45,
          overlayAlpha: 0.48,
          radialScrim: false,
          textShadows: _baseShadows,
          valuePill: false,
        );
      case HomeCardFocusOption.strongerTextShadow:
        return const _FocusConfig(
          mascotOpacity: 0.45,
          overlayAlpha: 0.28,
          radialScrim: false,
          textShadows: _strongShadows,
          valuePill: false,
        );
      case HomeCardFocusOption.valuePill:
        return const _FocusConfig(
          mascotOpacity: 0.45,
          overlayAlpha: 0.22,
          radialScrim: false,
          textShadows: _baseShadows,
          valuePill: true,
        );
    }
  }
}

class _LabStepsRing extends StatelessWidget {
  const _LabStepsRing({
    required this.remaining,
    required this.progress,
    required this.textShadows,
    required this.valuePill,
  });

  final int remaining;
  final double progress;
  final List<Shadow> textShadows;
  final bool valuePill;

  static const double size = 96;

  @override
  Widget build(BuildContext context) {
    final value = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$remaining',
          style: AppTextStyles.statValue.copyWith(
            color: AppColors.surface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1,
            shadows: textShadows,
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
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _LabStepsRingPainter(fraction: progress),
          ),
          if (valuePill)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.homeStepsGradientStart.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.surface.withValues(alpha: 0.18),
                ),
              ),
              child: value,
            )
          else
            value,
        ],
      ),
    );
  }
}

class _LabWeightValue extends StatelessWidget {
  const _LabWeightValue({
    required this.label,
    required this.unit,
    required this.textShadows,
    required this.valuePill,
  });

  final String label;
  final String unit;
  final List<Shadow> textShadows;
  final bool valuePill;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.statValue.copyWith(
            color: AppColors.surface,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1,
            shadows: textShadows,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: AppTextStyles.micro.copyWith(
            color: AppColors.surface.withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    if (!valuePill) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.homeWeightGradientStart.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.surface.withValues(alpha: 0.18),
        ),
      ),
      child: content,
    );
  }
}

class _LabMetricChip extends StatelessWidget {
  const _LabMetricChip({required this.icon, required this.label});

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

class _LabStepsRingPainter extends CustomPainter {
  _LabStepsRingPainter({required this.fraction});

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
  bool shouldRepaint(covariant _LabStepsRingPainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }
}
