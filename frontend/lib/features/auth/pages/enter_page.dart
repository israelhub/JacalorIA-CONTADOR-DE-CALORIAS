import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_route.dart';

import '../../../shared/theme/app_theme.dart';
import '../../home/pages/home_shell_page.dart';
import '../../onboarding/pages/welcome_page.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';
import 'sign_up_page.dart';
import '../widgets/enter_form.dart';
import '../widgets/enter_header.dart';
import '../widgets/enter_mascot.dart';

class EnterPage extends StatefulWidget {
  const EnterPage({super.key});

  @override
  State<EnterPage> createState() => _EnterPageState();
}

class _EnterPageState extends State<EnterPage> {
  final AuthController _authController = AuthController();

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    await _authController.signInWithGoogle();
    if (!mounted) {
      return;
    }

    if (_authController.token == null) {
      if (_authController.isGoogleSignInCancelled) {
        return;
      }

      final errorMessage =
          _authController.error ??
          'Nao foi possivel entrar com Google. Tente novamente.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    final nextPage = _authController.shouldCompleteOnboarding
        ? const WelcomePage()
        : HomeShellPage.fromLaunch();
    context.pushAndRemoveUntilSlidePage(nextPage, (route) => false);
  }

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
              children: [const EnterHeader()],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AnimatedBuilder(
                animation: _authController,
                builder: (context, _) => EnterForm(
                  onContinueWithGooglePressed: _authController.isLoading
                      ? null
                      : _handleGoogleLogin,
                  onCreateAccountPressed: () {
                    context.pushSlidePage(const SignUpPage());
                  },
                  onLoginPressed: () {
                    context.pushSlidePage(const LoginPage());
                  },
                ),
              ),
            ),
            const EnterMascot(),
          ],
        ),
      ),
    );
  }
}
