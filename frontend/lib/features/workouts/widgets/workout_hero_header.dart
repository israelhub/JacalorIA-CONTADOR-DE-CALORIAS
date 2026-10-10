import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

const workoutHeroContentOverlap = 48.0;

class WorkoutHeroHeader extends StatelessWidget {
  const WorkoutHeroHeader({super.key, required this.onImportWithAi});

  static const assetPath = 'assets/images/jaca_gym_hero.jpg';

  final VoidCallback? onImportWithAi;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: AppColors.brand300,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.15, -0.55),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.brand300,
                      AppColors.brand300.withValues(alpha: 0.96),
                      AppColors.brand300.withValues(alpha: 0.72),
                      AppColors.brand300.withValues(alpha: 0.18),
                    ],
                    stops: const [0, 0.52, 0.78, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                topInset + AppSpacing.xl,
                AppSpacing.pageHorizontal,
                72,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fichas',
                    style: AppTextStyles.missionsTitle.copyWith(
                      color: AppColors.brand900Variant,
                      fontSize: 28,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      'Monte suas fichas ou deixe a IA trazer do bloco de notas.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.brand900Variant,
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 64),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      key: const ValueKey('workout-import-ai'),
                      onPressed: onImportWithAi,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand900Variant,
                        foregroundColor: AppColors.surface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                      label: Text(
                        'Trazer fichas com IA',
                        style: AppTextStyles.missionsCardTitle.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
