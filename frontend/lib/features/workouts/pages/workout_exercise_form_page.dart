import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../models/workout_models.dart';
import '../widgets/workout_form_sheets.dart';

class WorkoutExerciseFormPage extends StatefulWidget {
  const WorkoutExerciseFormPage({super.key, this.exercise});

  final WorkoutExercise? exercise;

  @override
  State<WorkoutExerciseFormPage> createState() =>
      _WorkoutExerciseFormPageState();
}

class _WorkoutExerciseFormPageState extends State<WorkoutExerciseFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  String? _error;

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise?.name ?? '');
    _setsController = TextEditingController(
      text: widget.exercise?.sets.toString() ?? '3',
    );
    _repsController = TextEditingController(
      text: widget.exercise?.reps.toString() ?? '12',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) {
      setState(() {
        _error = null;
      });
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    final sets = int.tryParse(_setsController.text.trim()) ?? 0;
    final reps = int.tryParse(_repsController.text.trim()) ?? 0;

    if (name.isEmpty) {
      setState(() {
        _error = 'Digite o nome do exercício para continuar.';
      });
      return;
    }
    if (sets < 1 || reps < 1) {
      setState(() {
        _error = 'Informe séries e reps maiores que zero.';
      });
      return;
    }

    Navigator.of(context).pop(
      WorkoutExerciseDraft(
        name: name,
        sets: sets,
        reps: reps,
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _labeledInput({
    required String label,
    required Widget input,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(label),
        const SizedBox(height: AppSpacing.sm),
        input,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBackPageHeader(
        title: _isEditing ? 'Editar exercício' : 'Adicionar exercício',
      ),
      body: AppBackPageContent(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.lg,
            AppSpacing.pageHorizontal,
            homeShellScrollBottomInset(context),
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
                Text(
                  _isEditing ? 'Ajuste o exercício' : 'Monte o exercício',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _isEditing
                      ? 'Atualize o nome, as séries e as repetições.'
                      : 'Informe o nome, as séries e as repetições.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _labeledInput(
                  label: 'Exercício',
                  input: AppInput(
                    controller: _nameController,
                    hintText: 'Ex.: Supino reto',
                    showBorder: true,
                    showShadow: false,
                    onChanged: (_) => _clearError(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _labeledInput(
                        label: 'Séries',
                        input: AppInput(
                          controller: _setsController,
                          hintText: 'Ex.: 3',
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          showBorder: true,
                          showShadow: false,
                          onChanged: (_) => _clearError(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Column(
                        children: [
                          Opacity(
                            opacity: 0,
                            child: _fieldLabel('x'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            height: 48,
                            child: Center(
                              child: Text(
                                'x',
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _labeledInput(
                        label: 'Repetições',
                        input: AppInput(
                          controller: _repsController,
                          hintText: 'Ex.: 12',
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          showBorder: true,
                          showShadow: false,
                          onChanged: (_) => _clearError(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textError,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppButton(
                  label: _isEditing ? 'Salvar' : 'Adicionar',
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
