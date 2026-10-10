import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_date_picker.dart';
import '../helpers/home_date_helpers.dart';

class HomeWeekDateSelector extends StatelessWidget {
  const HomeWeekDateSelector({
    super.key,
    required this.selectedDate,
    required this.onSelected,
    this.today,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  final DateTime? today;

  static const _visiblePastDays = 5;
  static const _pickerPastDays = 365;
  static const _chipHeight = 64.0;
  static const _chipGap = AppSpacing.xs;

  Future<void> _openCalendar(BuildContext context) async {
    final end = normalizeHomeDate(today ?? DateTime.now());
    final firstDate = DateTime(end.year, end.month, end.day - _pickerPastDays);
    final selected = normalizeHomeDate(selectedDate);
    final initialDate = selected.isBefore(firstDate)
        ? firstDate
        : (selected.isAfter(end) ? end : selected);

    final picked = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: end,
    );
    if (picked == null) {
      return;
    }
    onSelected(normalizeHomeDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final end = normalizeHomeDate(today ?? DateTime.now());
    final days = homeSelectableWeekDays(
      today: end,
      pastDays: _visiblePastDays,
    );

    return SizedBox(
      height: _chipHeight,
      child: Row(
        children: [
          Expanded(
            child: _DateChipShell(
              key: const ValueKey('home-week-calendar'),
              selected: false,
              onTap: () => _openCalendar(context),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 22,
                color: AppColors.brand900Variant,
              ),
            ),
          ),
          for (final day in days) ...[
            const SizedBox(width: _chipGap),
            Expanded(
              child: _DayChip(
                key: ValueKey(
                  'home-week-day-'
                  '${day.year.toString().padLeft(4, '0')}-'
                  '${day.month.toString().padLeft(2, '0')}-'
                  '${day.day.toString().padLeft(2, '0')}',
                ),
                weekday: homeWeekdayLabel(day),
                day: day.day.toString().padLeft(2, '0'),
                selected: isSameHomeDate(day, selectedDate),
                onTap: () => onSelected(day),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    super.key,
    required this.weekday,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final String weekday;
  final String day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _DateChipShell(
      selected: selected,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekday,
            style: AppTextStyles.micro.copyWith(
              fontSize: 11,
              height: 1.1,
              color: selected ? AppColors.surface : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            day,
            style: AppTextStyles.homeAction.copyWith(
              fontSize: 16,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.surface : AppColors.brand900Variant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChipShell extends StatelessWidget {
  const _DateChipShell({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);

    return Material(
      color: selected ? AppColors.action500 : AppColors.homeCardSurface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
