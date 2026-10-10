import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../helpers/workout_import_template.dart';

class WorkoutImportPage extends StatefulWidget {
  const WorkoutImportPage({super.key});

  @override
  State<WorkoutImportPage> createState() => _WorkoutImportPageState();
}

class _WorkoutImportPageState extends State<WorkoutImportPage> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _error = 'Cole suas fichas para continuar.';
      });
      return;
    }

    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: const AppBackPageHeader(title: 'Trazer fichas com IA'),
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
                  'Traga suas anotações de treino',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Colando o que você já anotou, a IA monta os treinos, exercícios e o histórico de carga.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  key: const ValueKey('workout-import-entry-field'),
                  controller: _controller,
                  maxLines: 16,
                  minLines: 12,
                  hintText: workoutImportTemplate.trim(),
                  textAlignVertical: TextAlignVertical.top,
                  showBorder: true,
                  showShadow: false,
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  onChanged: (_) {
                    if (_error != null) {
                      setState(() {
                        _error = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textError,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppButton(label: 'Organizar com a IA', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
