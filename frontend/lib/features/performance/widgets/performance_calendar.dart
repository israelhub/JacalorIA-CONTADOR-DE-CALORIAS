import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../helpers/performance_month_helpers.dart';
import '../models/monthly_performance.dart';

class PerformanceCalendar extends StatelessWidget {
  const PerformanceCalendar({
    super.key,
    required this.month,
    required this.days,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onDayTap,
    this.isLoading = false,
  });

  final DateTime month;
  final List<PerformanceCalendarDay> days;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime>? onDayTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final firstDayWeekIndex = DateTime(month.year, month.month, 1).weekday % 7;
    final gridCells = <Widget>[];

    for (var i = 0; i < firstDayWeekIndex; i++) {
      gridCells.add(const SizedBox.shrink());
    }

    for (final day in days) {
      gridCells.add(
        _CalendarDayCell(
          date: DateTime(month.year, month.month, day.day),
          day: day,
          onTap: onDayTap,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.performanceCardBorder, width: 2),
        boxShadow: AppShadows.performanceCard,
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _CalendarActionButton(
                icon: Icons.chevron_left,
                onTap: isLoading ? null : onPreviousMonth,
              ),
              Expanded(
                child: Text(
                  performanceMonthLabel(month),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.performanceMonthTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
              ),
              _CalendarActionButton(
                icon: Icons.chevron_right,
                onTap: isLoading ? null : onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const _WeekDaysHeader(),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const spacing = AppSpacing.xs;
              final width = constraints.maxWidth;
              final itemSize = math.max(40.0, (width - (spacing * 6)) / 7);

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: gridCells
                    .map(
                      (Widget cell) => SizedBox(
                        width: itemSize,
                        height: itemSize,
                        child: cell,
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.borderAlt, height: 1),
          const SizedBox(height: AppSpacing.lg),
          const _CalendarLegend(),
        ],
      ),
    );
  }
}

class _CalendarActionButton extends StatelessWidget {
  const _CalendarActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        width: AppSpacing.xxl + AppSpacing.sm,
        height: AppSpacing.xxl + AppSpacing.sm,
        child: Icon(
          icon,
          color: onTap == null
              ? AppColors.textTertiary
              : AppColors.brand900Variant,
          size: AppSpacing.xl + AppSpacing.xs,
        ),
      ),
    );
  }
}

class _WeekDaysHeader extends StatelessWidget {
  const _WeekDaysHeader();

  static const List<String> _labels = <String>[
    'D',
    'S',
    'T',
    'Q',
    'Q',
    'S',
    'S',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _labels
          .map(
            (String label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.performanceCardCaption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.day,
    this.onTap,
  });

  final DateTime date;
  final PerformanceCalendarDay day;
  final ValueChanged<DateTime>? onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (day.status) {
      PerformanceDayStatus.goalAchieved => AppColors.action500,
      PerformanceDayStatus.mealRegistered => AppColors.accent500,
      PerformanceDayStatus.noRecord => null,
    };

    final textColor = switch (day.status) {
      PerformanceDayStatus.goalAchieved => AppColors.surface,
      PerformanceDayStatus.mealRegistered => AppColors.brand900Variant,
      PerformanceDayStatus.noRecord => AppColors.textTertiary,
    };

    final content = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${day.day}',
        style: AppTextStyles.performanceDayNumber.copyWith(color: textColor),
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: () => onTap!(date),
      borderRadius: BorderRadius.circular(10),
      child: content,
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const <Widget>[
        _LegendItem(label: 'Meta atingida', color: AppColors.action500),
        SizedBox(width: AppSpacing.md),
        _LegendItem(
          label: 'Refeição registrada',
          color: AppColors.performanceLegendMeal,
        ),
        SizedBox(width: AppSpacing.md),
        _LegendItem(
          label: 'Sem registro',
          color: null,
          borderColor: AppColors.performanceLegendNoRecordBorder,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.color,
    this.borderColor,
  });

  final String label;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: AppSpacing.md,
          height: AppSpacing.md,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.performanceCardMicro.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
