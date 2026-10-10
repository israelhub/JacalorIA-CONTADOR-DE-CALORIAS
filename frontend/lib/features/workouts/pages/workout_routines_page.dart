import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_confirm_modal.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_toast.dart';
import '../helpers/workout_formatters.dart';
import '../models/workout_models.dart';
import '../services/workout_service.dart';
import 'workout_routine_name_page.dart';

class WorkoutRoutinesPage extends StatefulWidget {
  const WorkoutRoutinesPage({
    super.key,
    required this.routines,
    required this.selectedRoutineId,
    WorkoutService? service,
  }) : _service = service ?? const WorkoutService();

  final List<WorkoutRoutine> routines;
  final String? selectedRoutineId;
  final WorkoutService _service;

  @override
  State<WorkoutRoutinesPage> createState() => _WorkoutRoutinesPageState();
}

class _WorkoutRoutinesPageState extends State<WorkoutRoutinesPage> {
  late List<WorkoutRoutine> _routines;
  late String? _selectedRoutineId;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _routines = List<WorkoutRoutine>.of(widget.routines);
    _selectedRoutineId = widget.selectedRoutineId;
  }

  Future<void> _createRoutine() async {
    if (_isBusy) {
      return;
    }

    final suggested = suggestNextRoutineName(
      _routines.map((routine) => routine.name),
    );
    final name = await context.pushSlidePage<String>(
      WorkoutRoutineNamePage(
        title: 'Novo treino',
        confirmLabel: 'Criar treino',
        initialName: suggested,
      ),
    );
    if (name == null || name.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _isBusy = true;
    });
    try {
      final routine = await widget._service.createRoutine(name: name);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(routine.id);
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

  Future<void> _renameRoutine(WorkoutRoutine routine) async {
    if (_isBusy) {
      return;
    }

    final name = await context.pushSlidePage<String>(
      WorkoutRoutineNamePage(
        title: 'Renomear treino',
        confirmLabel: 'Salvar',
        initialName: routine.name,
      ),
    );
    if (name == null || name.isEmpty || name == routine.name || !mounted) {
      return;
    }

    setState(() {
      _isBusy = true;
    });
    try {
      final updated = await widget._service.renameRoutine(
        routineId: routine.id,
        name: name,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _routines = [
          for (final item in _routines)
            if (item.id == updated.id) updated else item,
        ];
      });
      AppToast.success(context, message: 'Treino atualizado.');
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

  Future<void> _deleteRoutine(WorkoutRoutine routine) async {
    if (_isBusy) {
      return;
    }

    final confirmed = await AppConfirmModal.show(
      context,
      title: 'Apagar ${routine.name}?',
      message: 'Os exercícios e o histórico de carga desse treino somem junto.',
      confirmLabel: 'Apagar',
      isDanger: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isBusy = true;
    });
    try {
      await widget._service.deleteRoutine(routineId: routine.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _routines = [
          for (final item in _routines)
            if (item.id != routine.id) item,
        ];
        if (_selectedRoutineId == routine.id) {
          _selectedRoutineId =
              _routines.isEmpty ? null : _routines.first.id;
        }
      });
      AppToast.success(context, message: '${routine.name} apagado.');
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
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: const AppBackPageHeader(title: 'Fichas'),
      body: AppBackPageContent(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.lg,
            AppSpacing.pageHorizontal,
            AppSpacing.xxxl,
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                children: [
                  for (final (index, routine) in _routines.indexed) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.sm),
                    _RoutineRow(
                      key: ValueKey('workout-routine-row-${routine.id}'),
                      label: routine.name,
                      selected: routine.id == _selectedRoutineId,
                      onTap: () => Navigator.of(context).pop(routine.id),
                      onEdit: _isBusy ? null : () => _renameRoutine(routine),
                      onDelete: _isBusy ? null : () => _deleteRoutine(routine),
                    ),
                  ],
                  if (_routines.isNotEmpty)
                    const SizedBox(height: AppSpacing.sm),
                  _RoutineRow(
                    key: const ValueKey('workout-routine-row-add'),
                    label: null,
                    selected: false,
                    onTap: _isBusy ? null : _createRoutine,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final String? label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final isAdd = label == null;
    final radius = BorderRadius.circular(AppRadius.md);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: height,
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: isAdd ? AppSpacing.lg : AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.missionsXpPill : AppColors.insetSurface,
            borderRadius: radius,
          ),
          child: isAdd
              ? const Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 28,
                    color: AppColors.action500,
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        label!,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.brand900Variant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _RowIconButton(
                      key: ValueKey('workout-routine-edit-$label'),
                      icon: Icons.edit_outlined,
                      color: AppColors.brand900Variant,
                      onTap: onEdit,
                    ),
                    _RowIconButton(
                      key: ValueKey('workout-routine-delete-$label'),
                      icon: Icons.delete_outline,
                      color: AppColors.textError,
                      onTap: onDelete,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RowIconButton extends StatelessWidget {
  const _RowIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 20, color: color),
    );
  }
}
