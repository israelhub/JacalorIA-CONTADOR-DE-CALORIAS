import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_date_picker.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../home/helpers/home_date_helpers.dart';
import '../../profile/widgets/profile_section_card.dart';
import '../../workouts/widgets/workout_day_exercise_card.dart';
import '../helpers/social_model_parsers.dart';
import '../models/social_member_daily_workouts.dart';
import '../services/social_service.dart';

class SocialMemberDailyWorkoutsSection extends StatefulWidget {
  const SocialMemberDailyWorkoutsSection({
    super.key,
    required this.memberUserId,
    this.groupId,
    this.viaUserId,
    SocialService? service,
  }) : service = service ?? const SocialService();

  final String memberUserId;
  final String? groupId;
  final String? viaUserId;
  final SocialService service;

  @override
  State<SocialMemberDailyWorkoutsSection> createState() =>
      _SocialMemberDailyWorkoutsSectionState();
}

class _SocialMemberDailyWorkoutsSectionState
    extends State<SocialMemberDailyWorkoutsSection> {
  SocialMemberDailyWorkouts? _data;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({DateTime? date}) async {
    final hasData = _data != null;
    setState(() {
      _isLoading = !hasData;
      _isRefreshing = hasData;
      _error = null;
    });

    try {
      final result = await widget.service.fetchPublicProfileDailyWorkouts(
        userId: widget.memberUserId,
        date: date != null ? _toDayKey(date) : _data?.date,
        groupId: widget.groupId,
        viaUserId: widget.viaUserId,
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
      final message = socialFriendlyError(
        error,
        fallback: 'Não foi possível carregar treinos do perfil.',
      );
      final shouldHide =
          message.toLowerCase().contains('não encontrado') ||
          message.toLowerCase().contains('nao encontrado');
      setState(() {
        if (shouldHide) {
          _data = const SocialMemberDailyWorkouts(
            enabled: false,
            date: null,
            startsAt: null,
            endsAt: null,
            entries: [],
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
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.cardGap),
        child: Column(
          children: [
            AppSkeletonBox(height: 22, width: 120),
            SizedBox(height: AppSpacing.md),
            AppSkeletonBox(height: WorkoutDayExerciseCard.height),
            SizedBox(height: AppSpacing.md),
            AppSkeletonBox(height: WorkoutDayExerciseCard.height),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.cardGap),
        child: ProfileSectionCard(
          title: 'Treinos',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        ),
      );
    }

    final data = _data;
    if (data == null || !data.enabled) {
      return const SizedBox.shrink();
    }

    final selectedDate =
        _selectedDate ?? _parseDayKey(data.date) ?? DateTime.now();
    final entries = data.entries;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.cardGap),
      child: ProfileSectionCard(
        title: 'Treinos',
        trailing: InkWell(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.isPrivate) ...[
              Text(
                'Visível só para você. Seus treinos estão privados.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
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
            else if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'Nenhum treino registrado neste dia.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ..._buildWorkoutCards(entries),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWorkoutCards(List<SocialMemberDailyWorkoutEntry> entries) {
    final widgets = <Widget>[];
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      if (index > 0) {
        widgets.add(const SizedBox(height: AppSpacing.md));
      }
      widgets.add(
        WorkoutDayExerciseCard(
          key: ValueKey(entry.id),
          entry: entry.toDayEntry(),
          backgroundColor: AppColors.insetSurface,
          onTap: () {},
          onDelete: null,
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
