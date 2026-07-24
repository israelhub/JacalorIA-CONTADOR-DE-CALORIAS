import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/macro_progress_indicator.dart';
import '../../food_analysis/models/food_meal_record.dart';
import '../helpers/home_date_helpers.dart';
import '../helpers/home_goal_helpers.dart';
import '../helpers/home_greeting_helpers.dart';

class HomeDailyGoalWithMascot extends StatefulWidget {
  const HomeDailyGoalWithMascot({
    super.key,
    required this.mascotAsset,
    required this.records,
    required this.selectedDate,
    this.idleMascotVideoAsset,
    this.mascotVideoAsset,
    this.playMascotVideo = false,
    this.onMascotVideoCompleted,
    this.userProfile,
  });

  final String mascotAsset;
  final List<FoodMealRecord> records;
  final DateTime selectedDate;
  final String? idleMascotVideoAsset;
  final String? mascotVideoAsset;
  final bool playMascotVideo;
  final VoidCallback? onMascotVideoCompleted;
  final Map<String, dynamic>? userProfile;

  static const double _mascotOffsetY = -137;
  static const double _mascotSize = 200;

  @override
  State<HomeDailyGoalWithMascot> createState() =>
      _HomeDailyGoalWithMascotState();
}

class _HomeDailyGoalWithMascotState extends State<HomeDailyGoalWithMascot> {
  Timer? _celebrationTimer;

  @override
  void initState() {
    super.initState();
    _syncCelebrationTimer();
  }

  @override
  void didUpdateWidget(covariant HomeDailyGoalWithMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCelebrationTimer();
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    super.dispose();
  }

  void _syncCelebrationTimer() {
    _celebrationTimer?.cancel();
    _celebrationTimer = null;
    if (!widget.playMascotVideo) {
      return;
    }

    _celebrationTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) {
        return;
      }
      widget.onMascotVideoCompleted?.call();
    });
  }

  String? _resolveAnimationAsset(String? assetPath) {
    if (assetPath == null || assetPath.isEmpty) {
      return null;
    }
    return assetPath;
  }

  @override
  Widget build(BuildContext context) {
    final celebrationAsset = widget.playMascotVideo
        ? _resolveAnimationAsset(widget.mascotVideoAsset)
        : null;
    final idleAsset = _resolveAnimationAsset(widget.idleMascotVideoAsset);
    final objective = readHomeObjective(widget.userProfile);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.homeMetaCardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.homeMetaCardBorder, width: 1.5),
        boxShadow: AppShadows.homeMetaCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              HomeDailyGoalCard(
                key: const ValueKey('home-daily-goal-card'),
                records: widget.records,
                selectedDate: widget.selectedDate,
                userProfile: widget.userProfile,
              ),
              Positioned(
                top: HomeDailyGoalWithMascot._mascotOffsetY,
                child: IgnorePointer(
                  child: SizedBox(
                    key: const ValueKey('home-mascot-overlay'),
                    width: HomeDailyGoalWithMascot._mascotSize,
                    height: HomeDailyGoalWithMascot._mascotSize,
                    child:
                        (celebrationAsset != null
                            ? Image.asset(
                                celebrationAsset,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              )
                            : idleAsset != null
                            ? Image.asset(
                                idleAsset,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              )
                            : null) ??
                        Image.asset(widget.mascotAsset, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Text(
              calorieGoalExplanationForObjective(objective),
              key: const ValueKey('home-daily-goal-explanation'),
              softWrap: true,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted.withValues(alpha: 0.72),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeDailyGoalCard extends StatelessWidget {
  const HomeDailyGoalCard({
    super.key,
    required this.records,
    required this.selectedDate,
    this.userProfile,
  });

  final List<FoodMealRecord> records;
  final DateTime selectedDate;
  final Map<String, dynamic>? userProfile;

  @override
  Widget build(BuildContext context) {
    final normalizedSelectedDate = normalizeHomeDate(selectedDate);
    final todayRecords = records
        .where((record) {
          final createdAt = record.createdAt;
          return createdAt != null &&
              isSameHomeDate(createdAt, normalizedSelectedDate);
        })
        .toList(growable: false);

    final totalCalories = readHomeProfileInt(userProfile, const [
      'daily_calorie_goal',
      'dailyCalorieGoal',
    ], fallback: 2000);
    final consumedCalories = todayRecords.fold(0, (sum, r) => sum + r.calories);
    final objective = readHomeObjective(userProfile);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
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
                objective: objective,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _GoalStats(
                  records: todayRecords,
                  consumedCalories: consumedCalories,
                  totalCalories: totalCalories,
                  objective: objective,
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
    required this.objective,
  });

  final int consumedCalories;
  final int totalCalories;
  final HomeObjective objective;

  @override
  Widget build(BuildContext context) {
    final exceededCalories = consumedCalories - totalCalories;
    final isExceeded = isCalorieGoalExceededForObjective(
      consumedCalories: consumedCalories,
      goalCalories: totalCalories,
      objective: objective,
    );
    final progressToGoal = totalCalories <= 0
        ? 0.0
        : (consumedCalories / totalCalories).clamp(0.0, 1.0);
    final exceededFraction = consumedCalories <= 0
        ? 0.0
        : (exceededCalories / consumedCalories).clamp(0.0, 1.0);
    final normalFraction = isExceeded
        ? (1.0 - exceededFraction)
        : progressToGoal;

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(88, 88),
            painter: _CalorieRingPainter(
              normalFraction: normalFraction,
              exceededFraction: isExceeded ? exceededFraction : 0,
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

class _CalorieRingPainter extends CustomPainter {
  _CalorieRingPainter({
    required this.normalFraction,
    required this.exceededFraction,
  });

  final double normalFraction;
  final double exceededFraction;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = AppColors.homeProgressTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final normalPaint = Paint()
      ..color = AppColors.action500
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final exceededPaint = Paint()
      ..color = AppColors.textError
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    final startAngle = -math.pi / 2;
    final normalSweep = math.pi * 2 * normalFraction.clamp(0.0, 1.0);
    if (normalSweep > 0) {
      canvas.drawArc(rect, startAngle, normalSweep, false, normalPaint);
    }

    final exceededSweep = math.pi * 2 * exceededFraction.clamp(0.0, 1.0);
    if (exceededSweep > 0) {
      canvas.drawArc(
        rect,
        startAngle + normalSweep,
        exceededSweep,
        false,
        exceededPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) {
    return oldDelegate.normalFraction != normalFraction ||
        oldDelegate.exceededFraction != exceededFraction;
  }
}

class _GoalStats extends StatelessWidget {
  const _GoalStats({
    required this.records,
    required this.consumedCalories,
    required this.totalCalories,
    required this.objective,
    this.userProfile,
  });

  final List<FoodMealRecord> records;
  final int consumedCalories;
  final int totalCalories;
  final HomeObjective objective;
  final Map<String, dynamic>? userProfile;

  @override
  Widget build(BuildContext context) {
    final remainingCalories = totalCalories - consumedCalories;
    final isExceeded = isCalorieGoalExceededForObjective(
      consumedCalories: consumedCalories,
      goalCalories: totalCalories,
      objective: objective,
    );

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
                highlightColor: isExceeded
                    ? AppColors.textError
                    : AppColors.action500,
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
    this.highlightColor,
  });

  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;

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
                  ? (highlightColor ?? AppColors.action500)
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
