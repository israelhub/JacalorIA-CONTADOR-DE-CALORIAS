import 'package:flutter/material.dart';

import '../../../core/notifications/meal_reminder_models.dart';
import '../../food_analysis/helpers/food_review_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_time_picker.dart';

/// Página dedicada para criar um lembrete (nome + horário).
///
/// Retorna um [MealReminderConfig] ao confirmar, ou `null` se cancelado.
class MealReminderCreatePage extends StatefulWidget {
  const MealReminderCreatePage({super.key});

  @override
  State<MealReminderCreatePage> createState() => _MealReminderCreatePageState();
}

class _MealReminderCreatePageState extends State<MealReminderCreatePage> {
  static const _initialTime = TimeOfDay(hour: 15, minute: 30);

  late final TextEditingController _titleController;
  late TimeOfDay _time;
  late String _suggestedTitle;
  bool _titleEditedByUser = false;

  @override
  void initState() {
    super.initState();
    _time = _initialTime;
    _suggestedTitle = foodMealTypeForHour(_time.hour).defaultTitle;
    _titleController = TextEditingController(text: _suggestedTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  Future<void> _pickTime() async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Horário do lembrete',
    );
    if (picked == null || !mounted) {
      return;
    }

    final nextSuggested = foodMealTypeForHour(picked.hour).defaultTitle;
    final currentTitle = _titleController.text.trim();
    final shouldSyncTitle =
        !_titleEditedByUser || currentTitle == _suggestedTitle;

    setState(() {
      _time = picked;
      _suggestedTitle = nextSuggested;
      if (shouldSyncTitle) {
        _titleController.text = nextSuggested;
        _titleEditedByUser = false;
      }
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      MealReminderConfig.custom(
        hour: _time.hour,
        minute: _time.minute,
        title: title,
      ),
    );
  }

  String get _timeLabel {
    final h = _time.hour.toString().padLeft(2, '0');
    final m = _time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Novo lembrete',
          style: AppTextStyles.homeSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Defina um nome e o horário em que deseja ser avisado.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppInputField(
                label: 'Nome',
                hint: 'Ex.: Lanche da tarde',
                controller: _titleController,
                keyboardType: TextInputType.text,
                onChanged: (_) {
                  setState(() {
                    _titleEditedByUser =
                        _titleController.text.trim() != _suggestedTitle;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Horário',
                style: AppTextStyles.captionStrong.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Material(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: AppColors.action500,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _timeLabel,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.brand900Variant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          'alterar',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.action500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: AppSpacing.huge + AppSpacing.xs,
                child: AppButton(
                  label: 'Adicionar lembrete',
                  onPressed: _canSave ? _save : null,
                  trailingIcon: Icons.check_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
