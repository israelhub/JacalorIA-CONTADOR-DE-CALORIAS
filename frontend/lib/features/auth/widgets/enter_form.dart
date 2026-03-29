import 'package:flutter/material.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/or_divider.dart';

class EnterForm extends StatelessWidget {
  const EnterForm({super.key, this.onCreateAccountPressed});

  final VoidCallback? onCreateAccountPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          onPressed: onCreateAccountPressed ?? () {},
        ),
        const SizedBox(height: 16),
        AppButton(
          variant: AppButtonVariant.outline,
          label: 'Já tenho uma conta',
          onPressed: () {},
        ),
      ],
    );
  }
}
