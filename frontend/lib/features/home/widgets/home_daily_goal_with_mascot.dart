import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/macro_progress_indicator.dart';
import '../../food_analysis/models/food_meal_record.dart';
import '../helpers/home_date_helpers.dart';
import '../helpers/home_greeting_helpers.dart';

class HomeDailyGoalWithMascot extends StatelessWidget {
  const HomeDailyGoalWithMascot({
    super.key,
    required this.mascotAsset,
    required this.records,
    this.userProfile,
  });

  final String mascotAsset;
  final List<FoodMealRecord> records;
  final Map<String, dynamic>? userProfile;

  static const double _mascotOffsetY = -137;
  static const double _mascotSize = 200;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        HomeDailyGoalCard(
          key: const ValueKey('home-daily-goal-card'),
          records: records,
          userProfile: userProfile,
        ),
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

class HomeDailyGoalCard extends StatelessWidget {
  const HomeDailyGoalCard({super.key, required this.records, this.userProfile});

  final List<FoodMealRecord> records;
  final Map<String, dynamic>? userProfile;

  @override
  Widget build(BuildContext context) {
    final todayRecords = records.where((record) {
      final createdAt = record.createdAt;
      return createdAt != null && isSameHomeDate(createdAt, DateTime.now());
    }).toList(growable: false);

    final totalCalories = readHomeProfileInt(userProfile, const [
      'daily_calorie_goal',
      'dailyCalorieGoal',
    ], fallback: 2000);
    final consumedCalories = todayRecords.fold(0, (sum, r) => sum + r.calories);

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
          Row(
            children: [
              _ProgressRing(
                consumedCalories: consumedCalories,
                totalCalories: totalCalories,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _GoalStats(
                  records: todayRecords,
                  consumedCalories: consumedCalories,
                  totalCalories: totalCalories,
                  userProfile: userProfile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.consumedCalories,
    required this.totalCalories,
  });

  final int consumedCalories;
  final int totalCalories;

  @override
  Widget build(BuildContext context) {
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
              value: totalCalories == 0 ? 0 : consumedCalories / totalCalories,
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
                '$consumedCalories',
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
  const _GoalStats({
    required this.records,
    required this.consumedCalories,
    required this.totalCalories,
    this.userProfile,
  });

  final List<FoodMealRecord> records;
  final int consumedCalories;
  final int totalCalories;
  final Map<String, dynamic>? userProfile;

  @override
  Widget build(BuildContext context) {
    final remainingCalories = totalCalories - consumedCalories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatColumn(
                label: 'Meta',
                value: totalCalories.toString(),
              ),
            ),
            Expanded(
              child: _StatColumn(
                label: 'Consumido',
                value: consumedCalories.toString(),
              ),
            ),
            Expanded(
              child: _StatColumn(
                label: 'Restante',
                value: remainingCalories.toString(),
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _MacroSection(records: records, userProfile: userProfile),
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
  const _MacroSection({required this.records, this.userProfile});

  final List<FoodMealRecord> records;
  final Map<String, dynamic>? userProfile;

  @override
  Widget build(BuildContext context) {
    final consumedProtein = records.fold(0, (sum, r) => sum + r.protein);
    final consumedCarbs = records.fold(0, (sum, r) => sum + r.carbs);
    final consumedFat = records.fold(0, (sum, r) => sum + r.fat);

    final goalProtein = readHomeProfileInt(userProfile, const [
      'daily_protein_goal',
      'dailyProteinGoal',
    ], fallback: 120);
    final goalCarbs = readHomeProfileInt(userProfile, const [
      'daily_carbs_goal',
      'dailyCarbsGoal',
    ], fallback: 200);
    final goalFat = readHomeProfileInt(userProfile, const [
      'daily_fat_goal',
      'dailyFatGoal',
    ], fallback: 60);

    return Row(
      children: [
        Expanded(
          child: _MacroProgressItem(
            label: 'Proteina',
            consumed: consumedProtein,
            goal: goalProtein,
            color: AppColors.homeMacroProtein,
            progressKey: const ValueKey('home-macro-progress-proteina'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MacroProgressItem(
            label: 'Carboidratos',
            consumed: consumedCarbs,
            goal: goalCarbs,
            color: AppColors.homeMacroCarbs,
            progressKey: const ValueKey('home-macro-progress-carboidratos'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MacroProgressItem(
            label: 'Gordura',
            consumed: consumedFat,
            goal: goalFat,
            color: AppColors.homeMacroFat,
            progressKey: const ValueKey('home-macro-progress-gordura'),
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
    required this.progressKey,
    required this.color,
  });

  final String label;
  final int consumed;
  final int goal;
  final Color color;
  final Key progressKey;

  @override
  Widget build(BuildContext context) {
    return MacroProgressIndicator(
      label: label,
      consumed: consumed,
      goal: goal,
      color: color,
      progressKey: progressKey,
    );
  }
}
