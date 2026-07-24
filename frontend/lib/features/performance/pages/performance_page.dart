import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_refresh_scroll_view.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../helpers/performance_month_helpers.dart';
import '../models/monthly_performance.dart';
import '../models/weight_history.dart';
import '../services/performance_service.dart';
import '../widgets/performance_calendar.dart';
import '../widgets/performance_macro_bar.dart';
import '../widgets/performance_stat_card.dart';
import '../widgets/weight_history_chart.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({
    super.key,
    PerformanceService? service,
    this.onDateSelected,
    this.refreshVersion = 0,
  }) : _service = service ?? const PerformanceService();

  final PerformanceService _service;
  final ValueChanged<DateTime>? onDateSelected;
  final int refreshVersion;

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage>
    with AutomaticKeepAliveClientMixin {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  MonthlyPerformance? _performance;
  bool _isLoading = true;
  bool _isMonthLoading = false;
  bool _isWeightHistoryLoading = false;
  String? _errorMessage;
  String _selectedWeightPeriod = '30';
  DateTimeRange? _customWeightRange;
  WeightHistory? _weightHistory;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPerformance(_selectedMonth);
    _loadWeightHistory();
  }

  @override
  void didUpdateWidget(covariant PerformancePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshVersion != oldWidget.refreshVersion) {
      _refreshOnEnter();
    }
  }

  Future<void> _refreshOnEnter() async {
    await Future.wait<void>([
      _loadPerformance(_selectedMonth, silent: true),
      _loadWeightHistory(silent: true),
    ]);
  }

  Future<void> _loadPerformance(DateTime month, {bool silent = false}) async {
    final hasPerformance = _performance != null;
    final nextLoading = !hasPerformance;
    final nextMonthLoading = hasPerformance && !silent;
    if (!silent ||
        _isLoading != nextLoading ||
        _isMonthLoading != nextMonthLoading ||
        _errorMessage != null) {
      setState(() {
        _isLoading = nextLoading;
        // Avoid flashing overlays when soft-refreshing cached content.
        _isMonthLoading = nextMonthLoading;
        _errorMessage = null;
      });
    }

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
        if (!silent || _performance == null) {
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        }
        _isMonthLoading = false;
      });
    }
  }

  Future<void> _loadWeightHistory({bool silent = false}) async {
    if (!silent && !_isWeightHistoryLoading) {
      setState(() {
        _isWeightHistoryLoading = true;
      });
    }

    try {
      final result = await widget._service.fetchWeightHistory(
        period: _selectedWeightPeriod,
        startDate: _customWeightRange?.start,
        endDate: _customWeightRange?.end,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _weightHistory = result;
        _isWeightHistoryLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (!silent) {
          _weightHistory = null;
        }
        _isWeightHistoryLoading = false;
      });
    }
  }

  Future<void> _onSelectWeightPeriod(String period) async {
    if (_isWeightHistoryLoading) {
      return;
    }

    if (period == 'custom') {
      final now = DateTime.now();
      final initialRange =
          _customWeightRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 29)),
            end: now,
          );
      final selectedRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now,
        initialDateRange: initialRange,
        locale: const Locale('pt', 'BR'),
        builder: (context, child) {
          final baseTheme = Theme.of(context);
          final colorScheme = baseTheme.colorScheme.copyWith(
            primary: AppColors.action500,
            onPrimary: AppColors.surface,
            secondary: AppColors.action500,
            onSecondary: AppColors.surface,
            surface: AppColors.surface,
            onSurface: AppColors.brand900Variant,
          );

          return Theme(
            data: baseTheme.copyWith(
              colorScheme: colorScheme,
              dialogBackgroundColor: AppColors.surface,
              datePickerTheme: baseTheme.datePickerTheme.copyWith(
                backgroundColor: AppColors.surface,
                headerBackgroundColor: AppColors.surface,
                headerForegroundColor: AppColors.brand900Variant,
                rangeSelectionBackgroundColor: AppColors.action500.withValues(
                  alpha: 0.18,
                ),
                dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.surface;
                  }

                  return AppColors.brand900Variant;
                }),
                dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.action500;
                  }

                  return Colors.transparent;
                }),
                todayForegroundColor: const WidgetStatePropertyAll(
                  AppColors.surface,
                ),
                todayBackgroundColor: const WidgetStatePropertyAll(
                  AppColors.action500,
                ),
                todayBorder: const BorderSide(color: AppColors.action500),
                cancelButtonStyle: TextButton.styleFrom(
                  foregroundColor: AppColors.action500,
                ),
                confirmButtonStyle: TextButton.styleFrom(
                  foregroundColor: AppColors.action500,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedRange == null) {
        return;
      }

      setState(() {
        _selectedWeightPeriod = 'custom';
        _customWeightRange = selectedRange;
      });
      await _loadWeightHistory();
      return;
    }

    setState(() {
      _selectedWeightPeriod = period;
      _customWeightRange = null;
    });
    await _loadWeightHistory();
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
    super.build(context);
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

    return AppRefreshScrollView(
      onRefresh: _refreshOnEnter,
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
                  title: 'Objetivos batidos',
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
                  icon: _weightTrendIcon(performance.weightDirection),
                  title: _weightTrendTitle(performance.weightDirection),
                  value:
                      '${performance.weightDifferenceKg.toStringAsFixed(1)} kg',
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Mês: ${performanceMonthLabel(monthDate)}',
            style: AppTextStyles.performanceCardMicro.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: 'Relatório de peso geral',
            titleStyle: AppTextStyles.performanceSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _WeightHistoryCard(
            selectedPeriod: _selectedWeightPeriod,
            onPeriodSelected: _onSelectWeightPeriod,
            isLoading: _isWeightHistoryLoading,
            history: _weightHistory,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  String _weightTrendTitle(String direction) {
    switch (direction) {
      case 'lost':
        return 'Emagreceu';
      case 'gained':
        return 'Engordou';
      default:
        return 'Manteve peso';
    }
  }

  IconData _weightTrendIcon(String direction) {
    switch (direction) {
      case 'lost':
        return Icons.trending_down;
      case 'gained':
        return Icons.trending_up;
      default:
        return Icons.trending_flat;
    }
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

class _WeightHistoryCard extends StatelessWidget {
  const _WeightHistoryCard({
    required this.selectedPeriod,
    required this.onPeriodSelected,
    required this.isLoading,
    required this.history,
  });

  final String selectedPeriod;
  final ValueChanged<String> onPeriodSelected;
  final bool isLoading;
  final WeightHistory? history;

  static const _periods = <MapEntry<String, String>>[
    MapEntry('7', '7d'),
    MapEntry('15', '15d'),
    MapEntry('30', '1 mês'),
    MapEntry('90', '3 meses'),
    MapEntry('180', '6 meses'),
    MapEntry('365', '1 ano'),
    MapEntry('custom', 'Personalizado'),
  ];

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
          if (isLoading)
            const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.action500),
              ),
            )
          else
            WeightHistoryChart(
              points: history?.points ?? const <WeightHistoryPoint>[],
            ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = AppSpacing.xs;
              const columns = 3;
              final itemWidth =
                  (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
              final standardPeriods = _periods
                  .where((entry) => entry.key != 'custom')
                  .toList(growable: false);
              final customPeriod = _periods.firstWhere(
                (entry) => entry.key == 'custom',
              );

              return Column(
                children: <Widget>[
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: standardPeriods
                        .map((entry) {
                          final isSelected = selectedPeriod == entry.key;
                          return SizedBox(
                            width: itemWidth,
                            child: ChoiceChip(
                              selected: isSelected,
                              showCheckmark: false,
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  entry.value,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              backgroundColor: AppColors.surfaceAlt,
                              selectedColor: AppColors.action500.withValues(
                                alpha: 0.2,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.action500
                                    : AppColors.borderAlt,
                              ),
                              labelStyle: AppTextStyles.performanceCardMicro
                                  .copyWith(
                                    color: isSelected
                                        ? AppColors.action500
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                              onSelected: (_) => onPeriodSelected(entry.key),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                  const SizedBox(height: spacing),
                  SizedBox(
                    width: double.infinity,
                    child: ChoiceChip(
                      selected: selectedPeriod == customPeriod.key,
                      showCheckmark: false,
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          customPeriod.value,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      backgroundColor: AppColors.surfaceAlt,
                      selectedColor: AppColors.action500.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: selectedPeriod == customPeriod.key
                            ? AppColors.action500
                            : AppColors.borderAlt,
                      ),
                      labelStyle: AppTextStyles.performanceCardMicro.copyWith(
                        color: selectedPeriod == customPeriod.key
                            ? AppColors.action500
                            : AppColors.textSecondary,
                        fontWeight: selectedPeriod == customPeriod.key
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      onSelected: (_) => onPeriodSelected(customPeriod.key),
                    ),
                  ),
                ],
              );
            },
          ),
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
