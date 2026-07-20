import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';

class SocialJoinGroupPage extends StatefulWidget {
  const SocialJoinGroupPage({super.key});

  @override
  State<SocialJoinGroupPage> createState() => _SocialJoinGroupPageState();
}

class _SocialJoinGroupPageState extends State<SocialJoinGroupPage> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.brand900Variant,
        title: Text(
          'Entrar',
          style: AppTextStyles.missionsSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insira um código de convite ou encontre grupos públicos para participar.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInputField(
                label: 'Código do grupo',
                hint: 'Ex: ABCD-1234',
                controller: _codeController,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Ver grupos públicos',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.of(context).pop(
                  const SocialJoinGroupDialogResult.openPublicGroups(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Entrar',
                onPressed: () => Navigator.of(context).pop(
                  SocialJoinGroupDialogResult.byCode(_codeController.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialJoinGroupDialogResult {
  const SocialJoinGroupDialogResult._({this.code, required this.openPublicGroups});

  const SocialJoinGroupDialogResult.byCode(String code)
      : this._(code: code, openPublicGroups: false);

  const SocialJoinGroupDialogResult.openPublicGroups()
      : this._(openPublicGroups: true);

  final String? code;
  final bool openPublicGroups;
}
