import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../widgets/home_meal_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _mealAsset =
      'assets/images/smiling green cartoon crocodile@2x.webp';
  static const _mealCardHeight =
      AppSpacing.huge + AppSpacing.xxxl + AppSpacing.md - 1;

  @override
  Widget build(BuildContext context) {
    return const _HomeBody();
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.xxl),
                          _Header(mascotAsset: HomePage._mealAsset),
                          const SizedBox(height: AppSpacing.xxxl),
                          _DailyGoalWithMascot(
                            mascotAsset: HomePage._mealAsset,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const _MealsHeader(),
                          const SizedBox(height: AppSpacing.sm),
                          const _AddMealAction(),
                          const SizedBox(height: AppSpacing.lg),
                          HomeMealCard(
                            cardKey: const ValueKey('home-meal-card-0'),
                            title: 'Lanche da tarde',
                            description: 'Maca e mix de castanhas',
                            kcal: '180 kcal',
                            time: '15:00',
                            imageAsset: HomePage._mealAsset,
                            height: HomePage._mealCardHeight,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          HomeMealCard(
                            cardKey: const ValueKey('home-meal-card-1'),
                            title: 'Almoco',
                            description: 'Frango grelhado, arroz e salada',
                            kcal: '580 kcal',
                            time: '12:15',
                            imageAsset: HomePage._mealAsset,
                            height: HomePage._mealCardHeight,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          HomeMealCard(
                            cardKey: const ValueKey('home-meal-card-2'),
                            title: 'Cafe da manha',
                            description: 'Aveia, banana e mel',
                            kcal: '320 kcal',
                            time: '07:30',
                            imageAsset: HomePage._mealAsset,
                            height: HomePage._mealCardHeight,
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _BottomNavigation(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.mascotAsset});

  final String mascotAsset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bom dia, ☀️',
                style: AppTextStyles.homeHello.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Jon',
                style: AppTextStyles.homeUserName.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
            ],
          ),
        ),
        ClipOval(
          child: SizedBox(
            width: AppSpacing.huge + AppSpacing.xs,
            height: AppSpacing.huge + AppSpacing.xs,
            child: Image.asset(mascotAsset, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }
}

class _DailyGoalWithMascot extends StatelessWidget {
  const _DailyGoalWithMascot({required this.mascotAsset});

  final String mascotAsset;

  static const double _mascotOffsetY = -137;

  static const double _mascotSize = 200;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        const _DailyGoalCard(key: ValueKey('home-daily-goal-card')),
        Positioned(
          top: _mascotOffsetY,
          child: SizedBox(
            key: const ValueKey('home-mascot-overlay'),
            width: _mascotSize,
            height: _mascotSize,
            child: Image.asset(mascotAsset, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.homeMetaCardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.homeMetaCardBorder, width: 1.5),
        boxShadow: AppShadows.homeMetaCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meta diaria de calorias',
            style: AppTextStyles.label.copyWith(
              color: AppColors.brand900Variant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Row(
            children: [
              _ProgressRing(),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: _GoalStats()),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing();

  @override
  Widget build(BuildContext context) {
    const consumedCalories = 1080;
    const totalCalories = 2000;
    final remainingCalories = totalCalories - consumedCalories;

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: CircularProgressIndicator(
              value: consumedCalories / totalCalories,
              strokeWidth: 10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.action500,
              ),
              backgroundColor: AppColors.homeProgressTrack,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$remainingCalories',
                key: const ValueKey('home-calorie-ring-value'),
                style: AppTextStyles.statValue.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              Text(
                'kcal',
                style: AppTextStyles.micro.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalStats extends StatelessWidget {
  const _GoalStats();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(
              child: _StatColumn(label: 'Meta', value: '2.000'),
            ),
            Expanded(
              child: _StatColumn(label: 'Consumido', value: '1.080'),
            ),
            Expanded(
              child: _StatColumn(
                label: 'Restante',
                value: '920',
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const _MacroSection(),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.captionStrong.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTextStyles.statValue.copyWith(
              color: highlight
                  ? AppColors.action500
                  : AppColors.brand900Variant,
            ),
          ),
        ),
      ],
    );
  }
}

class _MacroSection extends StatelessWidget {
  const _MacroSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _MacroProgressItem(
            label: 'Proteina',
            consumed: 78,
            goal: 120,
            color: AppColors.homeMacroProtein,
            progressKey: ValueKey('home-macro-progress-proteina'),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MacroProgressItem(
            label: 'Carboidratos',
            consumed: 156,
            goal: 200,
            color: AppColors.homeMacroCarbs,
            progressKey: ValueKey('home-macro-progress-carboidratos'),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MacroProgressItem(
            label: 'Gordura',
            consumed: 40,
            goal: 60,
            color: AppColors.homeMacroFat,
            progressKey: ValueKey('home-macro-progress-gordura'),
          ),
        ),
      ],
    );
  }
}

class _MacroProgressItem extends StatelessWidget {
  const _MacroProgressItem({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
    required this.progressKey,
  });

  final String label;
  final int consumed;
  final int goal;
  final Color color;
  final Key progressKey;

  @override
  Widget build(BuildContext context) {
    final progress = goal == 0 ? 0.0 : (consumed / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.captionStrong.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm / 2),
          child: SizedBox(
            height: AppSpacing.xs + 2,
            child: LinearProgressIndicator(
              key: progressKey,
              value: progress,
              backgroundColor: AppColors.homeProgressTrack,
              color: color,
              minHeight: AppSpacing.xs + 2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${consumed}g/${goal}g',
          style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MealsHeader extends StatelessWidget {
  const _MealsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Refeicoes de hoje',
            style: AppTextStyles.homeSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '15 mar',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _AddMealAction extends StatelessWidget {
  const _AddMealAction();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: HomePage._mealCardHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg - AppSpacing.xs),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.homeDashedBorder,
          borderRadius: AppRadius.lg - AppSpacing.xs,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSpacing.xxl + AppSpacing.xs,
                height: AppSpacing.xxl + AppSpacing.xs,
                decoration: const BoxDecoration(
                  color: AppColors.action500,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '+',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: AppColors.surface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Adicionar refeição',
                style: AppTextStyles.homeAction.copyWith(
                  color: AppColors.action500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final radius = Radius.circular(borderRadius);
    final rect = RRect.fromRectAndRadius(Offset.zero & size, radius);
    final path = Path()..addRRect(rect);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderBrandAlt)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: _BottomItem(
                label: 'Calendário',
                icon: Icons.calendar_month,
                color: AppColors.divider,
                keyLabel: const ValueKey('home-bottom-label-calendario'),
                keyIcon: const ValueKey('home-bottom-icon-calendario'),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _BottomItem(
                label: 'Inicio',
                icon: Icons.home_rounded,
                color: AppColors.action500,
                keyLabel: const ValueKey('home-bottom-label-inicio'),
                keyIcon: const ValueKey('home-bottom-icon-inicio'),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                key: const ValueKey('home-bottom-camera-button'),
                width: AppSpacing.huge + AppSpacing.xl,
                height: AppSpacing.huge + AppSpacing.xl,
                decoration: BoxDecoration(
                  color: AppColors.action500,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.homeActionCircle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.surface,
                  size: AppSpacing.xxxl,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _BottomItem(
                label: 'Missões',
                icon: Icons.track_changes,
                color: AppColors.divider,
                keyLabel: const ValueKey('home-bottom-label-missoes'),
                keyIcon: const ValueKey('home-bottom-icon-missoes'),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _BottomItem(
                label: 'Social',
                icon: Icons.person_outline,
                color: AppColors.divider,
                keyLabel: const ValueKey('home-bottom-label-social'),
                keyIcon: const ValueKey('home-bottom-icon-social'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.keyLabel,
    required this.keyIcon,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Key keyLabel;
  final Key keyIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, key: keyIcon, color: color, size: AppSpacing.xxxl),
        const SizedBox(height: AppSpacing.xs - 1),
        Text(
          label,
          key: keyLabel,
          style: AppTextStyles.homeBottomNav.copyWith(color: color),
        ),
      ],
    );
  }
}
