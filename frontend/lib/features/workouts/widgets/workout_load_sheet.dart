import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../helpers/workout_formatters.dart';
import '../models/workout_models.dart';
import 'workout_form_sheets.dart';

Future<WorkoutLoadDraft?> showWorkoutLoadSheet(
  BuildContext context, {
  required WorkoutExercise exercise,
  required DateTime recordedAt,
}) {
  return showModalBottomSheet<WorkoutLoadDraft>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (sheetContext) {
      return _WorkoutLoadSheet(exercise: exercise, recordedAt: recordedAt);
    },
  );
}

class _WorkoutLoadSheet extends StatefulWidget {
  const _WorkoutLoadSheet({required this.exercise, required this.recordedAt});

  final WorkoutExercise exercise;
  final DateTime recordedAt;

  @override
  State<_WorkoutLoadSheet> createState() => _WorkoutLoadSheetState();
}

class _WorkoutLoadSheetState extends State<_WorkoutLoadSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  double? get _suggestedWeight => widget.exercise.lastLoad?.weight;

  double? get _parsedWeight {
    final parsed = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final weight = _parsedWeight;
    if (weight == null) {
      return;
    }
    final day = widget.recordedAt;
    Navigator.of(context).pop(
      WorkoutLoadDraft(
        weight: weight,
        recordedAt: DateTime(day.year, day.month, day.day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final suggested = _suggestedWeight;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.exercise.name,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  suggested == null
                      ? 'Quanto você pegou?'
                      : 'Última vez: ${formatWorkoutWeight(suggested)} kg',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 96,
                        maxWidth: 180,
                      ),
                      child: TextField(
                        key: const ValueKey('workout-load-sheet-field'),
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        enableSuggestions: false,
                        autocorrect: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: AppTextStyles.headingLarge.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Ex.: 40',
                          hintStyle: AppTextStyles.headingLarge.copyWith(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'kg',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Salvar peso',
                  onPressed: _parsedWeight == null ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
