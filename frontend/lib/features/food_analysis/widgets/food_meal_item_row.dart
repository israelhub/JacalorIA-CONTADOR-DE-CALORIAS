import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/macro_progress_indicator.dart';
import '../models/food_analysis_result.dart';

class FoodMealItemRow extends StatefulWidget {
  const FoodMealItemRow({
    super.key,
    required this.item,
    required this.mealProtein,
    required this.mealCarbs,
    required this.mealFat,
  });

  final FoodAnalysisItem item;
  final int mealProtein;
  final int mealCarbs;
  final int mealFat;

  @override
  State<FoodMealItemRow> createState() => _FoodMealItemRowState();
}

class _FoodMealItemRowState extends State<FoodMealItemRow>
    with SingleTickerProviderStateMixin {
  static const Duration _expandDuration = Duration(milliseconds: 280);

  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _expanded = false;

  FoodAnalysisItem get _item => widget.item;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: _expandDuration,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchedFood = _item.matchedFood?.trim() ?? '';
    final carbs = _item.carbs.round();
    final protein = _item.protein.round();
    final fat = _item.fat.round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          _item.name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (_item.hasTacoMatch) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: _TacoStamp(),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: _expandDuration,
                          curve: Curves.easeOutCubic,
                          child: const Icon(
                            Icons.expand_more,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${_item.grams}${_item.unit}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_item.calories.round()}kcal',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AnimatedBuilder(
              animation: _expandController,
              builder: (context, child) {
                if (_expandController.isDismissed) {
                  return const SizedBox.shrink();
                }

                return ClipRect(
                  child: SizeTransition(
                    sizeFactor: _expandAnimation,
                    axisAlignment: -1,
                    child: FadeTransition(
                      opacity: _expandAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                );
              },
              child: _ExpandedMealItemDetails(
                matchedFood: matchedFood,
                hasTacoMatch: _item.hasTacoMatch,
                carbs: carbs,
                protein: protein,
                fat: fat,
                mealCarbs: widget.mealCarbs,
                mealProtein: widget.mealProtein,
                mealFat: widget.mealFat,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedMealItemDetails extends StatelessWidget {
  const _ExpandedMealItemDetails({
    required this.matchedFood,
    required this.hasTacoMatch,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.mealCarbs,
    required this.mealProtein,
    required this.mealFat,
  });

  final String matchedFood;
  final bool hasTacoMatch;
  final int carbs;
  final int protein;
  final int fat;
  final int mealCarbs;
  final int mealProtein;
  final int mealFat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTacoMatch && matchedFood.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Identificado na tabela TACO como: $matchedFood',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: MacroProgressIndicator(
                label: 'Carboidratos',
                consumed: carbs,
                goal: mealCarbs,
                color: AppColors.homeMacroCarbs,
                labelStyle: AppTextStyles.captionStrong.copyWith(
                  color: AppColors.brand900Variant,
                  fontWeight: FontWeight.w500,
                ),
                valueStyle: AppTextStyles.micro.copyWith(
                  color: AppColors.brand900Variant,
                  fontWeight: FontWeight.w500,
                ),
                trackColor: AppColors.homeProgressTrack,
                barHeight: 8,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: MacroProgressIndicator(
                label: 'Proteinas',
                consumed: protein,
                goal: mealProtein,
                color: AppColors.homeMacroProtein,
                labelStyle: AppTextStyles.captionStrong.copyWith(
                  color: AppColors.brand900Variant,
                  fontWeight: FontWeight.w500,
                ),
                valueStyle: AppTextStyles.micro.copyWith(
                  color: AppColors.brand900Variant,
                  fontWeight: FontWeight.w500,
                ),
                trackColor: AppColors.homeProgressTrack,
                barHeight: 8,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: MacroProgressIndicator(
                label: 'Gorduras',
                consumed: fat,
                goal: mealFat,
                color: AppColors.homeMacroFat,
                labelStyle: AppTextStyles.captionStrong.copyWith(
                  color: AppColors.brand900Variant,
                  fontWeight: FontWeight.w500,
                ),
                valueStyle: AppTextStyles.micro.copyWith(
                  color: AppColors.brand900Variant,
                  fontWeight: FontWeight.w500,
                ),
                trackColor: AppColors.homeProgressTrack,
                barHeight: 8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TacoStamp extends StatelessWidget {
  const _TacoStamp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.action500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.action500.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_outlined,
            size: 12,
            color: AppColors.brand900,
          ),
          const SizedBox(width: 3),
          Text(
            'TACO',
            style: AppTextStyles.micro.copyWith(
              color: AppColors.brand900,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
