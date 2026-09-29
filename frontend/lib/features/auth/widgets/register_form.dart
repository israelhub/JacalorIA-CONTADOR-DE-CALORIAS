import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/or_divider.dart';

class RegisterForm extends StatelessWidget {
  const RegisterForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppInputField(label: 'Nome', hint: 'Digite seu nome'),
        const SizedBox(height: AppSpacing.lg),
        const AppInputField(label: 'E-mail', hint: 'Digite seu email'),
        const SizedBox(height: AppSpacing.lg),
        const AppInputField(
          label: 'Senha',
          hint: 'Digite sua senha',
          obscureText: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppInputField(
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
