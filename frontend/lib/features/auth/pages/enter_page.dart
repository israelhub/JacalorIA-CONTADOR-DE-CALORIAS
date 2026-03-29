import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import 'sign_up_page.dart';
import '../widgets/enter_form.dart';
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
              child: EnterForm(
                onCreateAccountPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignUpPage(),
                    ),
                  );
                },
              ),
            ),
            const EnterMascot(),
          ],
        ),
      ),
    );
  }
}
