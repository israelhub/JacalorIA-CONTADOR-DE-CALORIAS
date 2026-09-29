import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

const performanceHeroCalendarOverlap = 48.0;

class PerformanceHeroBackdrop extends StatelessWidget {
  const PerformanceHeroBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: ColoredBox(
          color: AppColors.brand900,
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: PerformanceHeroJacaSilhouette()),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  topInset + AppSpacing.xl,
                  AppSpacing.lg,
                  72,
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PerformanceHeroJacaSilhouette extends StatelessWidget {
  const PerformanceHeroJacaSilhouette({super.key});

  static const _asset = 'assets/images/Jaca_acenando_v2.webp';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxHeight * 1.18).clamp(200.0, 320.0);
        return IgnorePointer(
          child: ExcludeSemantics(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Transform.translate(
                offset: Offset(size * 0.14, size * 0.22),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    AppColors.brand300.withValues(alpha: 0.22),
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    _asset,
                    height: size,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PerformanceHeroHeader extends StatelessWidget {
  const PerformanceHeroHeader({
    super.key,
    required this.streakDays,
    required this.streakMessage,
  });

  final int streakDays;
  final String streakMessage;

  @override
  Widget build(BuildContext context) {
    final unitLabel = streakDays == 1
        ? 'dia de sequência!'
        : 'dias de sequência!';

    return PerformanceHeroBackdrop(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Desempenho',
            textAlign: TextAlign.start,
            style: AppTextStyles.performanceTitle.copyWith(
              color: AppColors.surface,
              fontSize: 22,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRect(
                    child: Transform.scale(
                      scale: 1.18,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) {
                            return const RadialGradient(
                              center: Alignment(0, 0.12),
                              radius: 0.42,
                              colors: <Color>[
                                Color(0xFFFF8A3C),
                                Color(0xFFFFC48A),
                              ],
                            ).createShader(bounds);
                          },
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFFF8A3C),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text.rich(
                        TextSpan(
                          style: AppTextStyles.performanceTitle.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w700,
                          ),
                          children: <InlineSpan>[
                            TextSpan(
                              text: '$streakDays',
                              style: const TextStyle(fontSize: 38, height: 1),
                            ),
                            TextSpan(
                              text: ' $unitLabel',
                              style: const TextStyle(fontSize: 18, height: 1),
                            ),
                          ],
                        ),
                      ),
                      if (streakMessage.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          streakMessage,
                          style: AppTextStyles.performanceTitle.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
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
