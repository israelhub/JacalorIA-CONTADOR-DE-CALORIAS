import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_route.dart';

import '../controllers/auth_controller.dart';
import '../../home/pages/home_shell_page.dart';
import '../../onboarding/pages/welcome_page.dart';
import '../service/auth_service.dart';
import '../../../shared/theme/app_theme.dart';
import 'email_confirmation_page.dart';
import 'login_page.dart';
import '../widgets/sign_up_form.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || AuthService.globalToken == null) {
        return;
      }

      context.pushAndRemoveUntilSlidePage(
        HomeShellPage.fromLaunch(),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  Future<bool> _handleCreateAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final created = await _authController.createAccount(
      name: name,
      email: email,
      password: password,
    );

    if (!mounted) {
      return created;
    }

    if (created) {
      context.pushSlidePage(EmailConfirmationPage(email: email));
    } else if (_authController.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_authController.error!)));
    }

    return created;
  }

  Future<void> _handleGoogleSignIn() async {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Image(
                image: const AssetImage('assets/images/logo.webp'),
                height: AppSpacing.huge * 4 + AppSpacing.xl,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AnimatedBuilder(
                animation: _authController,
                builder: (context, _) {
                  return SignUpForm(
                    onCreateAccountPressed: _handleCreateAccount,
                    onContinueWithGooglePressed: _handleGoogleSignIn,
                    isLoading: _authController.isLoading,
                    onLoginPressed: () {
                      context.pushSlidePage(const LoginPage());
                    },
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
