import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class EnterMascot extends StatelessWidget {
  const EnterMascot({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Transform.translate(
          offset: const Offset(AppSpacing.xxl, 0),
          child: Image.asset(
            'assets/images/jacaTelaCadastro.png',
            width: 204,
            height: 320,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
