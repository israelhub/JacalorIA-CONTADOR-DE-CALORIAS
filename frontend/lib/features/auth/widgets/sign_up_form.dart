import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/or_divider.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SignUpTextField(label: 'Nome', hint: 'Digite seu nome'),
        const SizedBox(height: AppSpacing.lg),
        const _SignUpTextField(label: 'E-mail', hint: 'Digite seu email'),
        const SizedBox(height: AppSpacing.lg),
        const _SignUpTextField(
          label: 'Senha',
          hint: 'Digite sua senha',
          obscureText: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SignUpTextField(
          label: 'Confirmar senha',
          hint: 'Confirme sua senha',
          obscureText: true,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Criar conta',
          onPressed: () {},
          variant: AppButtonVariant.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        const OrDivider(),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Continuar com Google',
          onPressed: () {},
          variant: AppButtonVariant.google,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Já tem uma conta?',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            TextButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.action500,
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Entrar', style: AppTextStyles.bodyLarge),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignUpTextField extends StatelessWidget {
  const _SignUpTextField({
    required this.label,
    required this.hint,
    this.obscureText = false,
  });

  final String label;
  final String hint;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.subtitleLarge),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: const Border(
              top: BorderSide(
                color: AppColors.borderLight,
                width: AppSpacing.xs / 4,
              ),
              left: BorderSide(
                color: AppColors.borderLight,
                width: AppSpacing.xs / 4,
              ),
              right: BorderSide(
                color: AppColors.borderLight,
                width: AppSpacing.xs / 4,
              ),
              bottom: BorderSide(
                color: AppColors.borderLight,
                width: AppSpacing.xs / 2,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowButtonAlt,
                offset: Offset(0, AppSpacing.xs / 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: TextFormField(
            obscureText: obscureText,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
