import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../home/widgets/home_shell_layout.dart';

class WorkoutRoutineNamePage extends StatefulWidget {
  const WorkoutRoutineNamePage({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initialName = '',
    this.hint = 'Ex.: Treino A',
    this.cardTitle = 'Nome do treino',
    this.subtitle =
        'Escolha um nome curto, tipo Treino A ou Peito.',
  });

  final String title;
  final String confirmLabel;
  final String initialName;
  final String hint;
  final String cardTitle;
  final String subtitle;

  @override
  State<WorkoutRoutineNamePage> createState() => _WorkoutRoutineNamePageState();
}

class _WorkoutRoutineNamePageState extends State<WorkoutRoutineNamePage> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() {
        _error = 'Digite um nome para continuar.';
      });
      return;
    }

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBackPageHeader(title: widget.title),
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
                  widget.cardTitle,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  controller: _controller,
                  hintText: widget.hint,
                  showBorder: true,
                  showShadow: false,
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
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppButton(label: widget.confirmLabel, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
