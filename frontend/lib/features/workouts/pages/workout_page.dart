import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_ambient_page_glow.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_confirm_modal.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_refresh_scroll_view.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../helpers/workout_formatters.dart';
import '../models/workout_models.dart';
import '../services/workout_service.dart';
import '../widgets/workout_empty_state.dart';
import '../widgets/workout_exercise_card.dart';
import '../widgets/workout_form_sheets.dart';
import '../widgets/workout_hero_header.dart';
import '../widgets/workout_routine_chips.dart';
import 'workout_exercise_details_page.dart';
import 'workout_exercise_form_page.dart';
import 'workout_import_page.dart';
import 'workout_routine_name_page.dart';
import 'workout_routines_page.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({
    super.key,
    WorkoutService? service,
    this.refreshVersion = 0,
  }) : _service = service ?? const WorkoutService();

  final WorkoutService _service;
  final int refreshVersion;

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage>
    with AutomaticKeepAliveClientMixin {
  WorkoutOverview? _overview;
  String? _selectedRoutineId;
  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  WorkoutService get _service => widget._service;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WorkoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshVersion != oldWidget.refreshVersion) {
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent || _overview == null) {
      setState(() {
        _isLoading = _overview == null;
        _errorMessage = null;
      });
    }

    try {
      final overview = await _service.fetchWorkouts();
      if (!mounted) {
        return;
      }
      setState(() {
        _overview = overview;
        _selectedRoutineId = _resolveSelectedId(overview);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (!silent || _overview == null) {
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        }
      });
    }
  }

  String? _resolveSelectedId(WorkoutOverview overview) {
    if (overview.routines.any((routine) => routine.id == _selectedRoutineId)) {
      return _selectedRoutineId;
    }
    return overview.routines.isEmpty ? null : overview.routines.first.id;
  }

  WorkoutRoutine? get _selectedRoutine {
    final routines = _overview?.routines ?? const <WorkoutRoutine>[];
    for (final routine in routines) {
      if (routine.id == _selectedRoutineId) {
        return routine;
      }
    }
    return routines.isEmpty ? null : routines.first;
  }

  Future<void> _createRoutine() async {
    final suggested = suggestNextRoutineName(
      _overview?.routines.map((routine) => routine.name) ?? const <String>[],
    );
    final name = await context.pushSlidePage<String>(
      WorkoutRoutineNamePage(
        title: 'Novo treino',
        confirmLabel: 'Criar treino',
        initialName: suggested,
      ),
    );
    if (name == null || name.isEmpty) {
      return;
    }

    await _runBusy(() async {
      final routine = await _service.createRoutine(name: name);
      await _load(silent: true);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedRoutineId = routine.id;
      });
      AppToast.success(context, message: 'Treino $name criado.');
    });
  }

  Future<void> _renameRoutine(WorkoutRoutine routine) async {
    final name = await context.pushSlidePage<String>(
      WorkoutRoutineNamePage(
        title: 'Renomear treino',
        confirmLabel: 'Salvar',
        initialName: routine.name,
      ),
    );
    if (name == null || name.isEmpty || name == routine.name) {
      return;
    }

    await _runBusy(() async {
      await _service.renameRoutine(routineId: routine.id, name: name);
      await _load(silent: true);
      if (!mounted) {
        return;
      }
      AppToast.success(context, message: 'Treino atualizado.');
    });
  }

  Future<void> _deleteRoutine(WorkoutRoutine routine) async {
    final confirmed = await AppConfirmModal.show(
      context,
      title: 'Apagar ${routine.name}?',
      message: 'Os exercícios e o histórico de carga desse treino somem junto.',
      confirmLabel: 'Apagar',
      isDanger: true,
    );
    if (!confirmed) {
      return;
    }

    await _runBusy(() async {
      await _service.deleteRoutine(routineId: routine.id);
      await _load(silent: true);
      if (!mounted) {
        return;
      }
      AppToast.success(context, message: '${routine.name} apagado.');
    });
  }

  Future<void> _createExercise() async {
    final routine = _selectedRoutine;
    if (routine == null) {
      await _createRoutine();
      return;
    }

    final draft = await context.pushSlidePage<WorkoutExerciseDraft>(
      const WorkoutExerciseFormPage(),
    );
    if (draft == null ||
        draft.name.isEmpty ||
        draft.sets < 1 ||
        draft.reps < 1) {
      return;
    }

    await _runBusy(() async {
      await _service.createExercise(
        routineId: routine.id,
        name: draft.name,
        sets: draft.sets,
        reps: draft.reps,
      );
      await _load(silent: true);
      if (!mounted) {
        return;
      }
      AppToast.success(context, message: '${draft.name} entrou no treino.');
    });
  }

  Future<void> _openExerciseDetails(WorkoutExercise exercise) async {
    final routine = _selectedRoutine;
    final changed = await context.pushSlidePage<bool>(
      WorkoutExerciseDetailsPage(
        exercise: exercise,
        routineName: routine?.name ?? 'Treino',
        service: _service,
      ),
    );
    if (changed == true && mounted) {
      await _load(silent: true);
    }
  }

  Future<void> _importNotes() async {
    final text = await context.pushSlidePage<String>(const WorkoutImportPage());
    if (text == null || text.isEmpty) {
      return;
    }

    await _runBusy(() async {
      final overview = await _service.importFromText(text);
      if (!mounted) {
        return;
      }
      setState(() {
        _overview = overview;
        _selectedRoutineId = _resolveSelectedId(overview);
      });
      AppToast.success(
        context,
        message: 'Pronto. Seus treinos e o histórico de carga estão aqui.',
      );
    });
  }

  Future<void> _openRoutinesFolder() async {
    final routines = _overview?.routines ?? const <WorkoutRoutine>[];
    final selectedId = await context.pushSlidePage<String>(
      WorkoutRoutinesPage(
        routines: routines,
        selectedRoutineId: _selectedRoutineId,
        service: _service,
      ),
    );
    if (!mounted) {
      return;
    }
    if (selectedId != null) {
      setState(() {
        _selectedRoutineId = selectedId;
      });
    }
    await _load(silent: true);
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
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: AppAmbientPageBody(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const _WorkoutBodySkeleton();
    }

    if (_errorMessage != null && _overview == null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage ?? 'Não foi possível carregar os treinos.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: 'Tentar novamente', onPressed: _load),
              ],
            ),
          ),
        ),
      );
    }

    final routines = _overview?.routines ?? const <WorkoutRoutine>[];
    final bottomInset = homeShellScrollBottomInset(context);

    return AppRefreshScrollView(
      onRefresh: () => _load(silent: true),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkoutHeroHeader(
            onImportWithAi: _isBusy ? null : _importNotes,
          ),
          Transform.translate(
            offset: const Offset(0, -workoutHeroContentOverlap),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                0,
                AppSpacing.pageHorizontal,
                bottomInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPlanCard(routines),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(List<WorkoutRoutine> routines) {
    final routine = _selectedRoutine;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Fichas',
            trailing: _FolderButton(
              onTap: _isBusy ? null : _openRoutinesFolder,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (routines.isEmpty)
            WorkoutEmptyState(onCreateRoutine: _createRoutine)
          else if (routine != null) ...[
            WorkoutRoutineChips(
              routines: routines,
              selectedRoutineId: routine.id,
              onSelect: (id) {
                setState(() {
                  _selectedRoutineId = id;
                });
              },
              onRename: _renameRoutine,
              onDelete: _deleteRoutine,
            ),
            const SizedBox(height: AppSpacing.md),
            if (routine.exercises.isEmpty) ...[
              Text(
                'Coloca os exercícios dessa ficha. O peso você anota na Home.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ] else ...[
              for (final (index, exercise) in routine.exercises.indexed) ...[
                if (index > 0) const SizedBox(height: AppSpacing.md),
                WorkoutExerciseCard(
                  exercise: exercise,
                  onTap: () => _openExerciseDetails(exercise),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
            _WorkoutAddExerciseCard(
              onTap: _isBusy ? null : _createExercise,
            ),
          ],
        ],
      ),
    );
  }
}

class _FolderButton extends StatelessWidget {
  const _FolderButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.insetSurface,
      shape: const CircleBorder(),
      child: InkWell(
        key: const ValueKey('workout-routines-folder'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.folder_outlined,
            size: 20,
            color: AppColors.brand900Variant,
          ),
        ),
      ),
    );
  }
}

class _WorkoutAddExerciseCard extends StatelessWidget {
  const _WorkoutAddExerciseCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(WorkoutExerciseCard.radius);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('workout-add-exercise'),
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: WorkoutExerciseCard.height,
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
                'Adicionar exercício',
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

class _WorkoutBodySkeleton extends StatelessWidget {
  const _WorkoutBodySkeleton();

  static const Color _bone = Color.fromRGBO(25, 54, 41, 0.12);
  static const Color _boneHighlight = Color.fromRGBO(25, 54, 41, 0.22);

  @override
  Widget build(BuildContext context) {
    final bottomInset = homeShellScrollBottomInset(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: AppColors.brand300,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                topInset + AppSpacing.xl,
                AppSpacing.pageHorizontal,
                72,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonBox(
                    height: 28,
                    width: 120,
                    color: _bone,
                    highlightColor: _boneHighlight,
                  ),
                  SizedBox(height: AppSpacing.md),
                  AppSkeletonBox(
                    height: 16,
                    width: 200,
                    color: _bone,
                    highlightColor: _boneHighlight,
                  ),
                  SizedBox(height: 8),
                  AppSkeletonBox(
                    height: 16,
                    width: 160,
                    color: _bone,
                    highlightColor: _boneHighlight,
                  ),
                  SizedBox(height: 64),
                  AppSkeletonBox(
                    height: 52,
                    borderRadius: AppRadius.pill,
                    color: _bone,
                    highlightColor: _boneHighlight,
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -workoutHeroContentOverlap),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                0,
                AppSpacing.pageHorizontal,
                bottomInset,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        AppSkeletonBox(height: 22, width: 80),
                        Spacer(),
                        AppSkeletonBox(
                          width: 36,
                          height: 36,
                          borderRadius: AppRadius.pill,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Row(
                      children: [
                        Expanded(
                          child: AppSkeletonBox(
                            height: 36,
                            borderRadius: AppRadius.pill,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppSkeletonBox(
                            height: 36,
                            borderRadius: AppRadius.pill,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppSkeletonBox(
                            height: 36,
                            borderRadius: AppRadius.pill,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var index = 0; index < 3; index += 1) ...[
                      if (index > 0) const SizedBox(height: AppSpacing.md),
                      AppSkeletonBox(
                        height: WorkoutExerciseCard.height,
                        borderRadius: WorkoutExerciseCard.radius,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
