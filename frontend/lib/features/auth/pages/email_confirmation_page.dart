import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_route.dart';
import 'package:flutter/services.dart';

import '../controllers/auth_controller.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../onboarding/pages/welcome_page.dart';

class EmailConfirmationPage extends StatefulWidget {
  const EmailConfirmationPage({
    super.key,
    required this.email,
    this.onVerifyEmail,
    this.onResendCode,
  });

  final String email;
  final Future<bool> Function(String email, String code)? onVerifyEmail;
  final Future<bool> Function(String email)? onResendCode;

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  final AuthController _authController = AuthController();
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _isApplyingCode = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    _authController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (_isApplyingCode) {
      return;
    }

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.isEmpty) {
      if (_controllers[index].text.isNotEmpty) {
        _controllers[index].clear();
      }
      return;
    }

    if (digitsOnly.length > 1) {
      _applyCodeFrom(index, digitsOnly);
      return;
    }

    _controllers[index].value = TextEditingValue(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );

    if (index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  void _applyCodeFrom(int startIndex, String digits) {
    _isApplyingCode = true;
    try {
      final chars = digits.split('');
      var slot = startIndex;

      for (final char in chars) {
        if (slot >= _controllers.length) {
          break;
        }
        _controllers[slot].value = TextEditingValue(
          text: char,
          selection: const TextSelection.collapsed(offset: 1),
        );
        slot++;
      }

      if (slot < _focusNodes.length) {
        _focusNodes[slot].requestFocus();
      } else {
        FocusScope.of(context).unfocus();
      }
    } finally {
      _isApplyingCode = false;
    }
  }

  KeyEventResult _onCodeFieldKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }

    final isCurrentEmpty = _controllers[index].text.isEmpty;
    if (!isCurrentEmpty || index == 0) {
      return KeyEventResult.ignored;
    }

    final previousIndex = index - 1;
    _controllers[previousIndex].clear();
    _focusNodes[previousIndex].requestFocus();
    return KeyEventResult.handled;
  }

  String get _verificationCode => _controllers.map((controller) => controller.text).join();

  Future<void> _handleConfirm() async {
    final code = _verificationCode;
    if (code.length != _controllers.length) {
      _showMessage('Digite o código de 6 dígitos.');
      return;
    }

    final isVerified = widget.onVerifyEmail != null
        ? await widget.onVerifyEmail!(widget.email, code)
        : await _authController.verifyEmail(email: widget.email, code: code);

    if (!mounted) {
      return;
    }

    if (isVerified) {
      context.pushSlidePage(const WelcomePage());
      return;
    }

    _showMessage(_authController.error ?? 'Código inválido ou expirado.');
  }

  Future<void> _handleResendCode() async {
    final isResent = widget.onResendCode != null
        ? await widget.onResendCode!(widget.email)
        : await _authController.resendCode(email: widget.email);

    if (!mounted) {
      return;
    }

    if (isResent) {
      _showMessage('Código reenviado com sucesso.');
      return;
    }

    _showMessage(_authController.error ?? 'Erro ao reenviar código.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            const SizedBox(height: AppSpacing.huge - AppSpacing.sm),
            Expanded(
              child: Column(
                children: [
                  const Spacer(flex: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                    ),
                    child: Text(
                      'Confirme o seu e-mail',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.confirmationTitle.copyWith(
                        color: AppColors.brand900Variant,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                    ),
                    child: Text(
                      'Enviamos um código para ${widget.email}.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl + AppSpacing.sm - 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: (AppSpacing.xxl * 2) + AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        for (var index = 0; index < 6; index++) ...[
                          Expanded(
                            child: Container(
                              key: ValueKey('email-code-slot-$index'),
                              height: AppSpacing.huge + AppSpacing.sm,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                border: Border.all(
                                  color: AppColors.confirmationCodeBorder,
                                ),
                              ),
                              child: Center(
                                child: Focus(
                                  onKeyEvent: (node, event) =>
                                      _onCodeFieldKeyEvent(index, event),
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: AppTextStyles.headingSmall.copyWith(
                                      color: AppColors.brand900Variant,
                                    ),
                                    onChanged: (value) =>
                                        _onDigitChanged(index, value),
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (index < 5) const SizedBox(width: AppSpacing.md),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl + AppSpacing.sm - 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: (AppSpacing.xxl * 2) + AppSpacing.sm,
                    ),
                    child: AnimatedBuilder(
                      animation: _authController,
                      builder: (context, _) {
                        return SizedBox(
                          key: const ValueKey('email-confirm-button'),
                          height: AppSpacing.huge + AppSpacing.xs,
                          child: AppButton(
                            label: _authController.isLoading
                                ? 'Confirmando...'
                                : 'Confirmar',
                            onPressed: _authController.isLoading
                                ? null
                                : _handleConfirm,
                            variant: AppButtonVariant.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg + 2),
                  AnimatedBuilder(
                    animation: _authController,
                    builder: (context, _) {
                      return TextButton(
                        onPressed: _authController.isLoading
                            ? null
                            : _handleResendCode,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                        child: Text(
                          'Reenviar código',
                          style: AppTextStyles.confirmationResendLink,
                        ),
                      );
                    },
                  ),
                  const Spacer(flex: 7),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
