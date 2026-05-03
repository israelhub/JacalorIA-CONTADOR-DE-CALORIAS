import 'package:flutter/material.dart';

import '../helpers/auth_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/or_divider.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({
    super.key,
    this.onCreateAccountPressed,
    this.onContinueWithGooglePressed,
    this.onLoginPressed,
    this.isLoading = false,
  });

  final Future<bool> Function({
    required String name,
    required String email,
    required String password,
  })?
  onCreateAccountPressed;
  final VoidCallback? onContinueWithGooglePressed;
  final VoidCallback? onLoginPressed;
  final bool isLoading;

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
    widget.onCreateAccountPressed?.call(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInputField(
            label: 'Nome',
            hint: 'Digite seu nome',
            controller: _nameController,
            enabled: !widget.isLoading,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Informe seu nome';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInputField(
            label: 'E-mail',
            hint: 'Digite seu email',
            controller: _emailController,
            enabled: !widget.isLoading,
            validator: (value) {
              if (!AuthHelpers.isValidEmail((value ?? '').trim())) {
                return 'Informe um e-mail válido';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInputField(
            label: 'Senha',
            hint: 'Digite sua senha',
            obscureText: true,
            controller: _passwordController,
            enabled: !widget.isLoading,
            validator: (value) {
              if (!AuthHelpers.isValidPassword((value ?? '').trim())) {
                return 'A senha deve ter ao menos 8 caracteres e 1 numero';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInputField(
            label: 'Confirmar senha',
            hint: 'Confirme sua senha',
            obscureText: true,
            controller: _confirmPasswordController,
            enabled: !widget.isLoading,
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
              label: widget.isLoading ? 'Criando conta...' : 'Criar conta',
              onPressed: widget.isLoading ? null : _submit,
              variant: AppButtonVariant.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const OrDivider(),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Continuar com Google',
            onPressed: widget.isLoading
                ? null
                : widget.onContinueWithGooglePressed,
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
                onPressed:
                    widget.onLoginPressed ??
                    () {
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
