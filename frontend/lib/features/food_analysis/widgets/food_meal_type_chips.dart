import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../helpers/food_review_helpers.dart';

class FoodMealTypeChips extends StatelessWidget {
  const FoodMealTypeChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.keyPrefix = 'food-meal-type',
    this.includeAll = false,
    this.expand = false,
    this.unselectedColor = AppColors.insetSurface,
  });

  final FoodMealType? selected;
  final ValueChanged<FoodMealType?> onSelected;
  final String keyPrefix;
  final bool includeAll;
  final bool expand;
  final Color unselectedColor;

  static const double _height = AppSpacing.xxxl;

  @override
  Widget build(BuildContext context) {
    final types = FoodMealType.values;
    final itemCount = types.length + (includeAll ? 1 : 0);
    final shouldExpand = expand || includeAll;

    Widget chipAt(int index) {
      if (includeAll && index == 0) {
        return _MealTypeChip(
          keyPrefix: keyPrefix,
          label: 'Todos',
          valueKey: 'all',
          isSelected: selected == null,
          onTap: () => onSelected(null),
          expand: shouldExpand,
          unselectedColor: unselectedColor,
        );
      }

      final type = types[includeAll ? index - 1 : index];
      return _MealTypeChip(
        keyPrefix: keyPrefix,
        label: type.chipLabel,
        valueKey: type.apiValue,
        isSelected: selected == type,
        onTap: () => onSelected(type),
        expand: shouldExpand,
        unselectedColor: unselectedColor,
      );
    }

    if (shouldExpand) {
      return SizedBox(
        height: _height,
        child: Row(
          children: [
            for (var index = 0; index < itemCount; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(child: chipAt(index)),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => chipAt(index),
      ),
    );
  }
}

class _MealTypeChip extends StatelessWidget {
  const _MealTypeChip({
    required this.keyPrefix,
    required this.label,
    required this.valueKey,
    required this.isSelected,
    required this.onTap,
    required this.expand,
    required this.unselectedColor,
  });

  final String keyPrefix;
  final String label;
  final String valueKey;
  final bool isSelected;
  final VoidCallback onTap;
  final bool expand;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.action500 : unselectedColor,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        key: ValueKey('$keyPrefix-$valueKey'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: FoodMealTypeChips._height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: expand ? AppSpacing.xs : AppSpacing.lg,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.homeAction.copyWith(
              height: 1,
              fontSize: expand ? 13 : null,
              color: isSelected
                  ? AppColors.surface
                  : AppColors.brand900Variant,
            ),
          ),
        ),
      ),
    );
  }
}
