import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_route.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_toast.dart';
import '../controllers/auth_controller.dart';
import '../helpers/auth_helpers.dart';
import 'reset_password_code_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final AuthController _authController = AuthController();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _authController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    AppToast.error(context, message: message);
  }

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (!AuthHelpers.isValidEmail(email)) {
      _showError('Digite um e-mail valido.');
      return;
    }

    final sent = await _authController.forgotPassword(email: email);
    if (!mounted) {
      return;
    }

    if (sent) {
      context.pushSlidePage(ResetPasswordCodePage(email: email));
      return;
    }

    _showError(_authController.error ?? 'Nao foi possivel enviar o codigo.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Redefinir senha',
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
                        'Informe seu e-mail para receber o codigo de redefinicao.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Verificar na caixa de spam.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppInputField(
                        label: 'E-mail',
                        hint: 'Digite seu e-mail',
                        controller: _emailController,
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
                          label: 'Enviar codigo',
                          onPressed: _authController.isLoading
                              ? null
                              : _handleSendCode,
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
                              'Enviando codigo...',
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
