import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_ambient_page_glow.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_confirm_modal.dart';
import '../../../shared/widgets/app_expandable_header_menu.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../../performance/models/weight_history.dart';
import '../../performance/widgets/weight_history_chart.dart';
import '../helpers/workout_formatters.dart';
import '../models/workout_models.dart';
import '../services/workout_service.dart';
import '../widgets/workout_form_sheets.dart';
import 'workout_exercise_form_page.dart';
import 'workout_load_form_page.dart';

class WorkoutExerciseDetailsPage extends StatefulWidget {
  const WorkoutExerciseDetailsPage({
    super.key,
    required this.exercise,
    required this.routineName,
    WorkoutService? service,
  }) : _service = service ?? const WorkoutService();

  final WorkoutExercise exercise;
  final String routineName;
  final WorkoutService _service;

  @override
  State<WorkoutExerciseDetailsPage> createState() =>
      _WorkoutExerciseDetailsPageState();
}

class _WorkoutExerciseDetailsPageState
    extends State<WorkoutExerciseDetailsPage> {
  static const _periods = <MapEntry<String, String>>[
    MapEntry('7', '7d'),
    MapEntry('15', '15d'),
    MapEntry('30', '1m'),
    MapEntry('90', '3m'),
    MapEntry('180', '6m'),
    MapEntry('365', '1a'),
  ];

  late WorkoutExercise _exercise;
  bool _isBusy = false;
  bool _changed = false;
  String _selectedPeriod = '30';
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? get _periodStart {
    if (_selectedPeriod == 'custom') {
      return _customRange == null
          ? null
          : DateTime(
              _customRange!.start.year,
              _customRange!.start.month,
              _customRange!.start.day,
            );
    }

    final days = int.tryParse(_selectedPeriod) ?? 30;
    return _today.subtract(Duration(days: days - 1));
  }

  DateTime? get _periodEnd {
    if (_selectedPeriod == 'custom' && _customRange != null) {
      return DateTime(
        _customRange!.end.year,
        _customRange!.end.month,
        _customRange!.end.day,
      );
    }
    return _today;
  }

  List<WeightHistoryPoint> get _chartPoints {
    final start = _periodStart;
    final end = _periodEnd;
    final points = <WeightHistoryPoint>[];

    for (final load in _exercise.loads) {
      final day = DateTime(
        load.recordedAt.year,
        load.recordedAt.month,
        load.recordedAt.day,
      );
      if (start != null && day.isBefore(start)) {
        continue;
      }
      if (end != null && day.isAfter(end)) {
        continue;
      }
      points.add(
        WeightHistoryPoint(date: load.recordedAt, weight: load.weight),
      );
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  Future<void> _selectPeriod(String period) async {
    if (period == 'custom') {
      final now = DateTime.now();
      final initialRange =
          _customRange ??
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
        _selectedPeriod = 'custom';
        _customRange = selectedRange;
      });
      return;
    }

    setState(() {
      _selectedPeriod = period;
      _customRange = null;
    });
  }

  Future<void> _editExercise() async {
    final draft = await context.pushSlidePage<WorkoutExerciseDraft>(
      WorkoutExerciseFormPage(exercise: _exercise),
    );
    if (draft == null ||
        draft.name.isEmpty ||
        draft.sets < 1 ||
        draft.reps < 1) {
      return;
    }

    await _runBusy(() async {
      final updated = await widget._service.updateExercise(
        exerciseId: _exercise.id,
        name: draft.name,
        sets: draft.sets,
        reps: draft.reps,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _exercise = WorkoutExercise(
          id: updated.id,
          routineId: updated.routineId,
          name: updated.name,
          sets: updated.sets,
          reps: updated.reps,
          sortOrder: updated.sortOrder,
          lastLoad: _exercise.lastLoad,
          previousLoad: _exercise.previousLoad,
          loads: _exercise.loads,
        );
        _changed = true;
      });
    });
  }

  Future<void> _deleteExercise() async {
    final confirmed = await AppConfirmModal.show(
      context,
      title: 'Apagar ${_exercise.name}?',
      message: 'O histórico de carga desse exercício também some.',
      confirmLabel: 'Apagar',
      isDanger: true,
    );
    if (!confirmed) {
      return;
    }

    await _runBusy(() async {
      await widget._service.deleteExercise(exerciseId: _exercise.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    });
  }

  Future<void> _addLoad() async {
    final draft = await context.pushSlidePage<WorkoutLoadDraft>(
      WorkoutLoadFormPage(exercise: _exercise),
    );
    if (draft == null) {
      return;
    }

    await _runBusy(() async {
      final updated = await widget._service.upsertLoad(
        exerciseId: _exercise.id,
        weight: draft.weight,
        recordedAt: draft.recordedAt,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _exercise = updated;
        _changed = true;
      });
      AppToast.success(context, message: 'Carga registrada.');
    });
  }

  Future<void> _deleteLoad(WorkoutLoad load) async {
    await _runBusy(() async {
      await widget._service.deleteLoad(loadId: load.id);
      final overview = await widget._service.fetchWorkouts();
      if (!mounted) {
        return;
      }
      WorkoutExercise? refreshed;
      for (final routine in overview.routines) {
        for (final exercise in routine.exercises) {
          if (exercise.id == _exercise.id) {
            refreshed = exercise;
            break;
          }
        }
      }
      if (refreshed == null) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _exercise = refreshed!;
        _changed = true;
      });
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_isBusy) {
      return;
    }
    setState(() {
      _isBusy = true;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _exercise.lastLoad;
    final sortedLoads = [..._exercise.loads]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(result ?? (_changed ? true : null));
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        extendBodyBehindAppBar: true,
        appBar: AppBackPageHeader(
          title: 'Detalhes exercício',
          trailing: AppExpandableHeaderMenu(
            showShadow: true,
            actions: [
              AppExpandableHeaderMenuAction(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: _editExercise,
              ),
              AppExpandableHeaderMenuAction(
                label: 'Apagar',
                icon: Icons.delete_outline,
                color: AppColors.textError,
                onPressed: _deleteExercise,
              ),
            ],
          ),
        ),
        body: AppAmbientPageBody(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppBackPageHeader.contentTopInset(context) + AppSpacing.sm,
              AppSpacing.pageHorizontal,
              homeShellScrollBottomInset(context),
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.missionsActionIconBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            size: 20,
                            color: AppColors.action500,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _exercise.name,
                            style: AppTextStyles.homeUserName.copyWith(
                              color: AppColors.brand900Variant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ExerciseInfoRow(
                      label: 'Parte do treino',
                      value: widget.routineName,
                      icon: Icons.view_agenda_outlined,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ExerciseInfoRow(
                      label: 'Séries a executar',
                      value: '${_exercise.sets} × ${_exercise.reps}',
                      icon: Icons.repeat_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ExerciseInfoRow(
                      label: 'Último peso',
                      value: last == null
                          ? 'Sem registro'
                          : '${formatWorkoutWeight(last.weight)} kg',
                      icon: Icons.monitor_weight_outlined,
                      valueColor: last == null
                          ? AppColors.textSecondary
                          : AppColors.action500,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evolução da carga',
                      style: AppTextStyles.homeSectionTitle.copyWith(
                        color: AppColors.brand900Variant,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    WeightHistoryChart(
                      points: _chartPoints,
                      startDate: _periodStart,
                      applyBodyWeightFilter: false,
                      emptyLabel: 'Sem registros de carga neste período.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: _periods
                          .map((entry) {
                            final isSelected = _selectedPeriod == entry.key;
                            return Expanded(
                              child: Center(
                                child: Material(
                                  color: isSelected
                                      ? AppColors.action500.withValues(
                                          alpha: 0.2,
                                        )
                                      : AppColors.insetSurface,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => _selectPeriod(entry.key),
                                    child: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Center(
                                        child: Text(
                                          entry.value,
                                          style: AppTextStyles
                                              .performanceCardMicro
                                              .copyWith(
                                                color: isSelected
                                                    ? AppColors.action500
                                                    : AppColors.textSecondary,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      width: double.infinity,
                      child: ChoiceChip(
                        selected: _selectedPeriod == 'custom',
                        showCheckmark: false,
                        label: const SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Personalizado',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        backgroundColor: AppColors.insetSurface,
                        selectedColor: AppColors.action500.withValues(
                          alpha: 0.2,
                        ),
                        side: BorderSide.none,
                        labelStyle: AppTextStyles.performanceCardMicro.copyWith(
                          color: _selectedPeriod == 'custom'
                              ? AppColors.action500
                              : AppColors.textSecondary,
                          fontWeight: _selectedPeriod == 'custom'
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        onSelected: (_) => _selectPeriod('custom'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Histórico',
                      style: AppTextStyles.homeSectionTitle.copyWith(
                        color: AppColors.brand900Variant,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AddLoadCard(onTap: _isBusy ? null : _addLoad),
                    if (sortedLoads.isEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Nenhum registro de carga ainda.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else
                      ...sortedLoads.map((load) {
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: _LoadHistoryCard(
                            load: load,
                            onDelete: _isBusy ? null : () => _deleteLoad(load),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseInfoRow extends StatelessWidget {
  const _ExerciseInfoRow({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.insetSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.action500),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.brand900Variant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddLoadCard extends StatelessWidget {
  const _AddLoadCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('workout-add-load'),
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.insetSurface,
            borderRadius: radius,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                size: 22,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Adicionar carga',
                style: AppTextStyles.homeAction.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadHistoryCard extends StatelessWidget {
  const _LoadHistoryCard({required this.load, required this.onDelete});

  final WorkoutLoad load;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.insetSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Text(
            '${formatWorkoutWeight(load.weight)} kg',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.brand900Variant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              formatWorkoutDateLong(load.recordedAt),
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Apagar carga',
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.foodReviewDeleteIcon,
            ),
          ),
        ],
      ),
    );
  }
}
