import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_route.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../controllers/auth_controller.dart';
import '../helpers/auth_helpers.dart';
import 'login_page.dart';

class ResetPasswordNewPasswordPage extends StatefulWidget {
  const ResetPasswordNewPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  @override
  State<ResetPasswordNewPasswordPage> createState() =>
      _ResetPasswordNewPasswordPageState();
}

class _ResetPasswordNewPasswordPageState
    extends State<ResetPasswordNewPasswordPage> {
  final AuthController _authController = AuthController();
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _authController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleResetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!AuthHelpers.isValidPassword(newPassword)) {
      _showMessage('A senha deve ter ao menos 8 caracteres e 1 numero.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showMessage('As senhas nao conferem.');
      return;
    }

    final reseted = await _authController.resetPassword(
      email: widget.email,
      code: widget.code,
      newPassword: newPassword,
    );

    if (!mounted) {
      return;
    }

    if (reseted) {
      _showMessage('Senha redefinida com sucesso.');
      context.pushAndRemoveUntilSlidePage(const LoginPage(), (route) => false);
      return;
    }

    _showMessage(
      _authController.error ?? 'Nao foi possivel redefinir a senha.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Nova senha',
          style: AppTextStyles.homeSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _authController,
          builder: (context, _) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Defina sua nova senha para ${widget.email}.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppInputField(
                        label: 'Nova senha',
                        hint: 'Digite sua nova senha',
                        controller: _newPasswordController,
                        obscureText: true,
                        onChanged: (_) => _authController.clearError(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppInputField(
                        label: 'Confirmar senha',
                        hint: 'Confirme sua nova senha',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        onChanged: (_) => _authController.clearError(),
                      ),
                      if (_authController.error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _authController.error!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textError,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      SizedBox(
                        height: AppSpacing.huge + AppSpacing.xs,
                        child: AppButton(
                          label: 'Salvar nova senha',
                          onPressed: _authController.isLoading
                              ? null
                              : _handleResetPassword,
                          variant: AppButtonVariant.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_authController.isLoading)
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppColors.surface.withValues(alpha: 0.7),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.action500,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Redefinindo senha...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.brand900Variant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
