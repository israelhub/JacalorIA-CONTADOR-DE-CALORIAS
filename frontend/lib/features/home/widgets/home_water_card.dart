import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../helpers/home_date_helpers.dart';
import '../helpers/home_water_helpers.dart';

class HomeWaterCard extends StatelessWidget {
  const HomeWaterCard({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.goalMl,
    required this.onAdd,
  });

  final List<HomeWaterDay> days;
  final DateTime selectedDate;
  final int goalMl;
  final VoidCallback onAdd;

  static const double cardHeight = 120;
  static const Color _accent = AppColors.action500;

  @override
  Widget build(BuildContext context) {
    final selectedMl =
        days
            .where((day) => isSameHomeDate(day.date, selectedDate))
            .map((day) => day.milliliters)
            .firstOrNull ??
        0;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Container(
      key: const ValueKey('home-water-card'),
      width: double.infinity,
      height: cardHeight,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.homeCardSurface,
        borderRadius: radius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registre sua água!',
                  style: AppTextStyles.homeSectionTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const Spacer(),
                _WaterAmount(currentMl: selectedMl, goalMl: goalMl),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Align(
            alignment: Alignment.bottomRight,
            child: _WaterAddButton(onPressed: onAdd),
          ),
        ],
      ),
    );
  }
}

class _WaterAmount extends StatelessWidget {
  const _WaterAmount({required this.currentMl, required this.goalMl});

  final int currentMl;
  final int goalMl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$currentMl',
          key: const ValueKey('home-water-ring-value'),
          style: AppTextStyles.statValue.copyWith(
            color: AppColors.brand900Variant,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        Flexible(
          child: Text(
            ' / ${_goalText(goalMl)}',
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

  static String _goalText(int goalMl) {
    if (goalMl <= 0) {
      return '—';
    }
    if (goalMl >= 1000 && goalMl % 1000 == 0) {
      return '${(goalMl / 1000).toStringAsFixed(0)} L';
    }
    if (goalMl >= 1000) {
      return '${(goalMl / 1000).toStringAsFixed(1).replaceAll('.', ',')} L';
    }
    return '$goalMl ml';
  }
}

class _WaterAddButton extends StatelessWidget {
  const _WaterAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Adicionar água',
      child: Material(
        color: HomeWaterCard._accent,
        shape: const CircleBorder(),
        child: InkWell(
          key: const ValueKey('home-water-add'),
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.add_rounded,
              color: AppColors.surface,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
