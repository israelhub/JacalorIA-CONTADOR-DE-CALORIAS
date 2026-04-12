import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmailConfirmationPage(
            email: email,
          ),
        ),
      );
    } else if (_authController.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_authController.error!)));
    }

    return created;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Image(
                image: const AssetImage('assets/images/logo.png'),
                height: AppSpacing.huge * 4 + AppSpacing.xl,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AnimatedBuilder(
                animation: _authController,
                builder: (context, _) {
                  return SignUpForm(
                    onCreateAccountPressed: _handleCreateAccount,
                    isLoading: _authController.isLoading,
                    onLoginPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
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
