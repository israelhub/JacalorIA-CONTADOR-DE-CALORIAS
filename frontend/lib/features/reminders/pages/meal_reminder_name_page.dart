import 'package:flutter/material.dart';

import '../../../core/notifications/meal_reminder_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';

/// Edita o nome de um lembrete numa página dedicada.
///
/// Retorna o novo nome (não vazio) ao dar pop, ou `null` se cancelado.
class MealReminderNamePage extends StatefulWidget {
  const MealReminderNamePage({super.key, required this.config});

  final MealReminderConfig config;

  @override
  State<MealReminderNamePage> createState() => _MealReminderNamePageState();
}

class _MealReminderNamePageState extends State<MealReminderNamePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.config.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final title = _controller.text.trim();
    Navigator.of(context).pop(title.isEmpty ? null : title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: const AppBackPageHeader(title: 'Nome do lembrete'),
      body: AppBackPageContent(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Escolha um nome para reconhecer este lembrete.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppInputField(
                label: 'Nome',
                hint: 'Ex.: Lanche da tarde',
                controller: _controller,
                keyboardType: TextInputType.text,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: AppSpacing.huge + AppSpacing.xs,
                child: AppButton(
                  label: 'Salvar',
                  onPressed: _controller.text.trim().isEmpty ? null : _save,
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
