import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../helpers/performance_month_helpers.dart';
import '../models/monthly_performance.dart';
import '../services/performance_service.dart';
import '../widgets/performance_calendar.dart';
import '../widgets/performance_macro_bar.dart';
import '../widgets/performance_stat_card.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({
    super.key,
    PerformanceService? service,
    this.onDateSelected,
  }) : _service = service ?? const PerformanceService();

  final PerformanceService _service;
  final ValueChanged<DateTime>? onDateSelected;

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  MonthlyPerformance? _performance;
  bool _isLoading = true;
  bool _isMonthLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPerformance(_selectedMonth);
  }

  Future<void> _loadPerformance(DateTime month) async {
    final hasPerformance = _performance != null;
    setState(() {
      _isLoading = !hasPerformance;
      _isMonthLoading = hasPerformance;
      _errorMessage = null;
    });

    try {
      final result = await widget._service.fetchMonthlyPerformance(month);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedMonth = month;
        _performance = result;
        _isLoading = false;
        _isMonthLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _isMonthLoading = false;
      });
    }
  }

  void _goToPreviousMonth() {
    if (_isMonthLoading) {
      return;
    }

    final previous = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    _loadPerformance(previous);
  }

  void _goToNextMonth() {
    if (_isMonthLoading) {
      return;
    }

    final now = DateTime(DateTime.now().year, DateTime.now().month);
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(now)) {
      return;
    }

    _loadPerformance(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.action500),
      );
    }

    if (_errorMessage != null || _performance == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _errorMessage ?? 'Não foi possível carregar o desempenho.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Tentar novamente',
                onPressed: () => _loadPerformance(_selectedMonth),
              ),
            ],
          ),
        ),
      );
    }

    final performance = _performance!;
    final monthDate = DateTime(
      performance.calendarYear,
      performance.calendarMonth,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppPageHeader(
            title: 'Desempenho',
            icon: Icons.calendar_today_outlined,
            titleStyle: AppTextStyles.performanceTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
            iconSize: AppSpacing.xl + AppSpacing.xs,
          ),
          const SizedBox(height: AppSpacing.lg),
          _StreakCard(
            streakDays: performance.streakDays,
            message: performance.streakMessage,
          ),
          const SizedBox(height: AppSpacing.lg),
          _isMonthLoading
              ? const _PerformanceCalendarSkeleton()
              : PerformanceCalendar(
                  month: monthDate,
                  days: performance.calendarDays,
                  onPreviousMonth: _goToPreviousMonth,
                  onNextMonth: _goToNextMonth,
                  onDayTap: widget.onDateSelected,
                ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: 'Relatório do mês',
            titleStyle: AppTextStyles.performanceSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: PerformanceStatCard(
                  icon: Icons.gpp_good_outlined,
                  title: 'Meta batida',
                  value: '${performance.metGoalDays} dias',
                  subtitle: 'de ${performance.elapsedDays} dias',
                  iconColor: AppColors.action500,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PerformanceStatCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'Registros',
                  value: '${performance.registeredDays} dias',
                  subtitle: '${performance.consistencyPercent}% consistência',
                  iconColor: AppColors.accent500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: PerformanceStatCard(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Média diária',
                  value: '${performance.avgDailyCalories}',
                  subtitle: 'kcal por dia',
                  iconColor: AppColors.missionsChallenge,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PerformanceStatCard(
                  icon: Icons.trending_down,
                  title: 'Emagreceu',
                  value: '${performance.weightLostKg.toStringAsFixed(1)} kg',
                  subtitle: 'vs início do mês',
                  iconColor: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _HighlightCard(
            title: performance.highlightTitle,
            description: performance.highlightDescription,
            macroProgress: performance.macroProgress,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Mês: ${performanceMonthLabel(monthDate)}',
            style: AppTextStyles.performanceCardMicro.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceCalendarSkeleton extends StatelessWidget {
  const _PerformanceCalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.performanceCardBorder, width: 2),
        boxShadow: AppShadows.performanceCard,
      ),
      child: Column(
        children: const <Widget>[
          Row(
            children: <Widget>[
              AppSkeletonBox(
                width: AppSpacing.xxl + AppSpacing.sm,
                height: AppSpacing.xxl + AppSpacing.sm,
                borderRadius: AppRadius.pill,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppSkeletonBox(height: AppSpacing.lg, borderRadius: 10),
              ),
              SizedBox(width: AppSpacing.md),
              AppSkeletonBox(
                width: AppSpacing.xxl + AppSpacing.sm,
                height: AppSpacing.xxl + AppSpacing.sm,
                borderRadius: AppRadius.pill,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          AppSkeletonBox(height: 16, borderRadius: 10),
          SizedBox(height: AppSpacing.md),
          _PerformanceCalendarGridSkeleton(),
          SizedBox(height: AppSpacing.lg),
          Divider(color: AppColors.borderAlt, height: 1),
          SizedBox(height: AppSpacing.lg),
          AppSkeletonBox(height: 14, width: 260, borderRadius: 10),
        ],
      ),
    );
  }
}

class _PerformanceCalendarGridSkeleton extends StatelessWidget {
  const _PerformanceCalendarGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: List<Widget>.generate(
        35,
        (_) => const SizedBox(
          width: 40,
          height: 40,
          child: AppSkeletonBox(height: 40, borderRadius: 10),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakDays, required this.message});

  final int streakDays;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.action500,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.performanceStreak,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Sua sequência',
                  style: AppTextStyles.performanceStreakLabel.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  '$streakDays dias',
                  style: AppTextStyles.performanceStreakValue.copyWith(
                    color: AppColors.surface,
                  ),
                ),
                Text(
                  message,
                  style: AppTextStyles.performanceStreakMicro.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.surface,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.title,
    required this.description,
    required this.macroProgress,
  });

  final String title;
  final String description;
  final List<PerformanceMacroProgress> macroProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.performanceCardBorder, width: 2),
        boxShadow: AppShadows.performanceCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.pie_chart_outline,
                color: AppColors.accent500,
                size: AppSpacing.xl,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.performanceHighlightTitle.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
            ],
          ),
          if (description.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: AppTextStyles.performanceBody.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else
            const SizedBox(height: AppSpacing.md),
          ...macroProgress.map((PerformanceMacroProgress item) {
            final color = switch (item.key) {
              'protein' => AppColors.performanceLegendMeal,
              'fat' => AppColors.performanceMacroFat,
              _ => AppColors.action500,
            };

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: PerformanceMacroBar(
                label: item.label,
                percent: item.percent,
                fillColor: color,
              ),
            );
          }),
        ],
      ),
    );
  }
}
