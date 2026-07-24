import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_date_picker.dart';
import '../../food_analysis/models/food_meal_record.dart';
import '../../home/helpers/home_date_helpers.dart';
import '../../home/widgets/home_meal_card.dart';
import '../models/social_member_daily_meals.dart';
import '../services/social_service.dart';

class SocialMemberDailyMealsSection extends StatefulWidget {
  const SocialMemberDailyMealsSection({
    super.key,
    required this.groupId,
    required this.memberUserId,
    this.competitionType,
    SocialService? service,
  }) : service = service ?? const SocialService();

  final String groupId;
  final String memberUserId;
  final String? competitionType;
  final SocialService service;

  @override
  State<SocialMemberDailyMealsSection> createState() =>
      _SocialMemberDailyMealsSectionState();
}

class _SocialMemberDailyMealsSectionState
    extends State<SocialMemberDailyMealsSection> {
  static const double _mealCardHeight = 88;

  SocialMemberDailyMeals? _data;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  DateTime? _selectedDate;

  bool get _shouldLoad {
    final competitionType = widget.competitionType?.trim();
    if (competitionType == null || competitionType.isEmpty) {
      return true;
    }
    return competitionType == 'goal_average';
  }

  @override
  void initState() {
    super.initState();
    if (_shouldLoad) {
      _load();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _load({DateTime? date}) async {
    final hasData = _data != null;
    setState(() {
      _isLoading = !hasData;
      _isRefreshing = hasData;
      _error = null;
    });

    try {
      final result = await widget.service.fetchGroupMemberDailyMeals(
        groupId: widget.groupId,
        memberUserId: widget.memberUserId,
        date: date != null ? _toDayKey(date) : _data?.date,
      );
      if (!mounted) return;

      setState(() {
        _data = result;
        _selectedDate = _parseDayKey(result.date) ?? date ?? _selectedDate;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      final shouldHide = message.toLowerCase().contains('não encontrado') ||
          message.toLowerCase().contains('nao encontrado');
      setState(() {
        if (shouldHide) {
          _data = const SocialMemberDailyMeals(
            enabled: false,
            competitionType: '',
            date: null,
            startsAt: null,
            endsAt: null,
            totalCalories: 0,
            meals: [],
          );
          _error = null;
        } else {
          _error = message;
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final data = _data;
    if (data == null || !data.enabled) return;

    final firstDate = _parseDayKey(data.startsAt) ?? DateTime(2020);
    final lastDate = _parseDayKey(data.endsAt) ?? DateTime.now();
    final initialDate = _selectedDate ?? lastDate;
    final clampedInitial = initialDate.isBefore(firstDate)
        ? firstDate
        : (initialDate.isAfter(lastDate) ? lastDate : initialDate);

    final picked = await showAppDatePicker(
      context: context,
      initialDate: clampedInitial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null || !mounted) return;

    final normalized = normalizeHomeDate(picked);
    if (_selectedDate != null && isSameHomeDate(_selectedDate!, normalized)) {
      return;
    }

    setState(() => _selectedDate = normalized);
    await _load(date: normalized);
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldLoad) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xl),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.action500,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Refeições',
              style: AppTextStyles.missionsSectionTitle.copyWith(
                color: AppColors.brand900Variant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => _load(date: _selectedDate),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final data = _data;
    if (data == null || !data.enabled) {
      return const SizedBox.shrink();
    }

    final selectedDate =
        _selectedDate ?? _parseDayKey(data.date) ?? DateTime.now();
    final meals = data.meals;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Refeições',
                  style: AppTextStyles.missionsSectionTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
              ),
              InkWell(
                onTap: _isRefreshing ? null : _pickDate,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatHomeDateLabel(selectedDate),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${data.totalCalories} kcal no dia',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.action500,
                  ),
                ),
              ),
            )
          else if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Nenhuma refeição registrada neste dia.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ..._buildMealCards(meals),
        ],
      ),
    );
  }

  List<Widget> _buildMealCards(List<FoodMealRecord> meals) {
    final widgets = <Widget>[];
    for (var index = 0; index < meals.length; index++) {
      final meal = meals[index];
      if (index > 0) {
        widgets.add(const SizedBox(height: AppSpacing.sm));
      }
      widgets.add(
        HomeMealCard(
          cardKey: ValueKey(meal.id ?? '${meal.title}-$index'),
          title: meal.title,
          description: meal.description,
          kcal: meal.kcalLabel,
          time: meal.timeLabel,
          imageUrl: meal.imageUrl,
          imageAsset: meal.imageAsset,
          height: _mealCardHeight,
        ),
      );
    }
    return widgets;
  }

  String _toDayKey(DateTime date) {
    final normalized = normalizeHomeDate(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  DateTime? _parseDayKey(String? dayKey) {
    final raw = dayKey?.trim() ?? '';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      return null;
    }
    final parts = raw.split('-');
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }
}
