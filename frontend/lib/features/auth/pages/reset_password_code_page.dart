import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_route.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../controllers/auth_controller.dart';
import 'reset_password_new_password_page.dart';

class ResetPasswordCodePage extends StatefulWidget {
  const ResetPasswordCodePage({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordCodePage> createState() => _ResetPasswordCodePageState();
}

class _ResetPasswordCodePageState extends State<ResetPasswordCodePage> {
  final AuthController _authController = AuthController();
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _authController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleContinue() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showMessage('Digite o codigo de 6 digitos.');
      return;
    }

    final isValid = await _authController.validateResetCode(
      email: widget.email,
      code: code,
    );
    if (!mounted) {
      return;
    }

    if (!isValid) {
      _showMessage(_authController.error ?? 'Codigo invalido ou expirado.');
      return;
    }

    context.pushSlidePage(
      ResetPasswordNewPasswordPage(email: widget.email, code: code),
    );
  }

  Future<void> _handleResendCode() async {
    final sent = await _authController.forgotPassword(email: widget.email);
    if (!mounted) {
      return;
    }

    if (sent) {
      _showMessage('Codigo reenviado. Verificar na caixa de spam.');
      return;
    }

    _showMessage(
      _authController.error ?? 'Nao foi possivel reenviar o codigo.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Confirmar codigo',
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
                        'Digite o codigo enviado para ${widget.email}.',
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
                        label: 'Codigo',
                        hint: 'Digite o codigo de 6 digitos',
                        controller: _codeController,
                        keyboardType: TextInputType.number,
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
                          label: 'Continuar',
                          onPressed: _authController.isLoading
                              ? null
                              : _handleContinue,
                          variant: AppButtonVariant.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: _authController.isLoading
                            ? null
                            : _handleResendCode,
                        child: Text(
                          'Reenviar codigo',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.action500,
                            fontWeight: FontWeight.w700,
                          ),
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
                              'Validando codigo...',
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
