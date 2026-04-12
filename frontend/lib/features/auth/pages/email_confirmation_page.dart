import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../onboarding/pages/welcome_page.dart';

class EmailConfirmationPage extends StatefulWidget {
  const EmailConfirmationPage({super.key, required this.email});

  final String email;

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
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
                                color: AppColors.inputSurface,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
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
                    child: SizedBox(
                      key: const ValueKey('email-confirm-button'),
                      height: AppSpacing.huge + AppSpacing.xs,
                      child: AppButton(
                        label: 'Confirmar',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WelcomePage(),
                            ),
                          );
                        },
                        variant: AppButtonVariant.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg + 2),
                  TextButton(
                    onPressed: () {},
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
