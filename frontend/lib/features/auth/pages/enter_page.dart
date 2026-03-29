import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/or_divider.dart';
import '../widgets/enter_header.dart';
import '../widgets/enter_mascot.dart';

class EnterPage extends StatelessWidget {
  const EnterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const EnterHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    variant: AppButtonVariant.google,
                    label: 'Continuar com Google',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  const OrDivider(),
                  const SizedBox(height: 16),
                  AppButton(
                    variant: AppButtonVariant.primary,
                    label: 'Criar conta',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    variant: AppButtonVariant.outline,
                    label: 'Já tenho uma conta',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const EnterMascot(),
          ],
        ),
      ),
    );
  }
}
