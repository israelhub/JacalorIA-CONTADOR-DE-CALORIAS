import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_modal.dart';

class SocialJoinGroupDialog extends StatefulWidget {
  const SocialJoinGroupDialog({super.key});

  @override
  State<SocialJoinGroupDialog> createState() => _SocialJoinGroupDialogState();
}

class _SocialJoinGroupDialogState extends State<SocialJoinGroupDialog> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entrar em grupo',
            style: AppTextStyles.missionsSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
            onPressed: () => Navigator.of(context).pop(const SocialJoinGroupDialogResult.openPublicGroups()),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancelar',
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Entrar',
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(SocialJoinGroupDialogResult.byCode(_codeController.text)),
                ),
              ),
            ],
          ),
        ],
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
