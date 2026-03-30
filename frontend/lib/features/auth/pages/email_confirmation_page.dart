import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';

class EmailConfirmationPage extends StatefulWidget {
  const EmailConfirmationPage({super.key});

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

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
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
      return;
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
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
            SizedBox(
              height: AppSpacing.huge - AppSpacing.sm,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: IconButton(
                    key: const ValueKey('email-back-button'),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.brand900,
                    iconSize: AppSpacing.xl,
                    splashRadius: AppSpacing.xl,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Spacer(flex: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
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
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Text(
                      'Enviamos um código para o seu e-mail.',
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
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  maxLength: 1,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(1),
                                  ],
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: AppColors.brand900Variant,
                                  ),
                                  onChanged: (value) => _onDigitChanged(index, value),
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
                        onPressed: () {},
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
