import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_route.dart';

import '../../../shared/theme/app_theme.dart';
import 'login_page.dart';
import 'sign_up_page.dart';
import '../widgets/enter_form.dart';
import '../widgets/enter_header.dart';
import '../widgets/enter_mascot.dart';
import '../widgets/enter_pages_shortcut_button.dart';

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [const EnterHeader(), const EnterPagesShortcutButton()],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.5),
              child: EnterForm(
                onCreateAccountPressed: () {
                  context.pushSlidePage(const SignUpPage());
                },
                onLoginPressed: () {
                  context.pushSlidePage(const LoginPage());
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
