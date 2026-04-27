import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_route.dart';

import '../controllers/auth_controller.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_button.dart';
import 'package:jacaloria/shared/widgets/app_input.dart';
import '../../home/pages/home_shell_page.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.authController,
    this.initialErrorMessage,
  });

  final AuthController? authController;
  final String? initialErrorMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final AuthController _authController;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _authController = widget.authController ?? AuthController();
    _ownsController = widget.authController == null;

    final initialError = widget.initialErrorMessage;
    if (initialError != null && initialError.trim().isNotEmpty) {
      _authController.error = initialError.trim();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    if (_ownsController) {
      _authController.dispose();
    }
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final isSignedIn = await _authController.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || !isSignedIn) {
      return;
    }

    context.pushAndRemoveUntilSlidePage(const HomeShellPage(), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _authController,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xxxl),
                    Center(
                      child: Image.asset(
                        'assets/images/logo.webp',
                        height: AppSpacing.huge * 4 + AppSpacing.xl,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    AppInputField(
                      label: 'E-mail',
                      hint: 'Digite seu email',
                      controller: _emailController,
                      onChanged: (_) => _authController.clearError(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppInputField(
                      label: 'Senha',
                      hint: 'Digite sua senha',
                      controller: _passwordController,
                      obscureText: true,
                      onChanged: (_) => _authController.clearError(),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    SizedBox(
                      height: AppSpacing.huge + AppSpacing.xs,
                      child: AppButton(
                        label: 'Entrar',
                        onPressed:
                            _authController.isLoading ? null : _handleLogin,
                        variant: AppButtonVariant.primary,
                      ),
                    ),
                    if (_authController.error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _authController.error!,
                        key: const ValueKey('login-error-message'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textError,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.borderLight,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            'ou',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.borderLight,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: AppSpacing.huge + AppSpacing.xs,
                      child: AppButton(
                        label: 'Continuar com Google',
                        onPressed: () {},
                        variant: AppButtonVariant.google,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: RichText(
                        key: const ValueKey('signup-link'),
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Não tem uma conta ainda? ',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextSpan(
                              text: 'Cadastre-se',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.action500,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  context.pushSlidePage(const SignUpPage());
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
