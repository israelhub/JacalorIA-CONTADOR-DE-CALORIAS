import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_date_picker.dart';
import '../../../shared/widgets/app_input.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../helpers/workout_formatters.dart';
import '../models/workout_models.dart';
import '../widgets/workout_form_sheets.dart';

class WorkoutLoadFormPage extends StatefulWidget {
  const WorkoutLoadFormPage({
    super.key,
    this.exercise,
    this.recordedAt,
    this.lockDate = false,
  });

  final WorkoutExercise? exercise;
  final DateTime? recordedAt;
  final bool lockDate;

  @override
  State<WorkoutLoadFormPage> createState() => _WorkoutLoadFormPageState();
}

class _WorkoutLoadFormPageState extends State<WorkoutLoadFormPage> {
  late final TextEditingController _weightController;
  late DateTime _selectedDate;
  String? _error;

  double? get _suggestedWeight => widget.exercise?.lastLoad?.weight;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    final now = DateTime.now();
    final initial = widget.recordedAt ?? now;
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) {
      setState(() {
        _error = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final selected = await showAppDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _selectedDate = selected;
    });
  }

  void _submit() {
    final weight = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    if (weight == null || weight <= 0) {
      setState(() {
        _error = 'Informe um peso válido para continuar.';
      });
      return;
    }

    Navigator.of(
      context,
    ).pop(WorkoutLoadDraft(weight: weight, recordedAt: _selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    final exerciseName = widget.exercise?.name;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: const AppBackPageHeader(title: 'Adicionar carga'),
      body: AppBackPageContent(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppBackPageHeader.scrollTopInset(context, extra: AppSpacing.lg),
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
                  exerciseName == null
                      ? 'Quanto você pegou?'
                      : 'Quanto você pegou em $exerciseName?',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _suggestedWeight == null
                      ? 'Registre o peso usado nesse exercício.'
                      : 'Última vez: ${formatWorkoutWeight(_suggestedWeight!)} kg',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Peso (kg)',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppInput(
                  controller: _weightController,
                  hintText: 'Ex.: 40',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  showBorder: true,
                  showShadow: false,
                  onChanged: (_) => _clearError(),
                ),
                if (!widget.lockDate) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Dia',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        width: double.infinity,
                        padding: AppInputStyles.singleLineContentPadding,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: Text(
                          formatWorkoutDateLong(_selectedDate),
                          style: AppInputStyles.value,
                        ),
                      ),
                    ),
                  ),
                ],
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
                AppButton(label: 'Salvar peso', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
