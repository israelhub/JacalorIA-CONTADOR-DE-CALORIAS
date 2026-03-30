import 'package:flutter/material.dart';

import '../helpers/auth_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/or_divider.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({
    super.key,
    this.onCreateAccountPressed,
    this.onLoginPressed,
  });

  final VoidCallback? onCreateAccountPressed;
  final VoidCallback? onLoginPressed;

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    widget.onCreateAccountPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SignUpTextField(
            label: 'Nome',
            hint: 'Digite seu nome',
            controller: _nameController,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Informe seu nome';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SignUpTextField(
            label: 'E-mail',
            hint: 'Digite seu email',
            controller: _emailController,
            validator: (value) {
              if (!AuthHelpers.isValidEmail((value ?? '').trim())) {
                return 'Informe um e-mail válido';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SignUpTextField(
            label: 'Senha',
            hint: 'Digite sua senha',
            obscureText: true,
            controller: _passwordController,
            validator: (value) {
              if (!AuthHelpers.isValidPassword((value ?? '').trim())) {
                return 'A senha deve ter ao menos 6 dígitos';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SignUpTextField(
            label: 'Confirmar senha',
            hint: 'Confirme sua senha',
            obscureText: true,
            controller: _confirmPasswordController,
            validator: (value) {
              if ((value ?? '') != _passwordController.text) {
                return 'As senhas não conferem';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: AppSpacing.huge + AppSpacing.xs,
            child: AppButton(
              label: 'Criar conta',
              onPressed: _submit,
              variant: AppButtonVariant.primary,
            ),
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
                onPressed: widget.onLoginPressed ?? () {
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
      ),
    );
  }
}

class _SignUpTextField extends StatelessWidget {
  const _SignUpTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md - (AppSpacing.xs / 4)),
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                  onChanged: state.didChange,
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
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  top: AppSpacing.xs,
                ),
                child: Text(
                  state.errorText!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textError,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}



