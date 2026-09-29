import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/app_page_route.dart';

import '../controllers/auth_controller.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_button.dart';
import 'package:jacaloria/shared/widgets/app_input.dart';
import '../../home/pages/home_shell_page.dart';
import '../../onboarding/pages/welcome_page.dart';
import 'forgot_password_page.dart';
import 'sign_up_page.dart';
import '../../support/pages/support_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authController, this.initialErrorMessage});

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

    final nextPage = _authController.shouldCompleteOnboarding
        ? const WelcomePage()
        : HomeShellPage.fromLaunch();
    context.pushAndRemoveUntilSlidePage(nextPage, (route) => false);
  }

  Future<void> _handleGoogleLogin() async {
    await _authController.signInWithGoogle();
    if (!mounted || _authController.token == null) {
      if (_authController.isGoogleSignInCancelled) {
        return;
      }

      return;
    }

    context.pushAndRemoveUntilSlidePage(
      HomeShellPage.fromLaunch(),
      (route) => false,
    );
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _authController.isLoading
                            ? null
                            : () {
                                context.pushSlidePage(
                                  ForgotPasswordPage(
                                    initialEmail: _emailController.text.trim(),
                                  ),
                                );
                              },
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                        child: Text(
                          'Esqueci minha senha',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.action500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    SizedBox(
                      height: AppSpacing.huge + AppSpacing.xs,
                      child: AppButton(
                        label: _authController.isLoading
                            ? 'Entrando…'
                            : 'Entrar',
                        onPressed: _authController.isLoading
                            ? null
                            : _handleLogin,
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
                        onPressed: _authController.isLoading
                            ? null
                            : _handleGoogleLogin,
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
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: TextButton(
                        onPressed: _authController.isLoading
                            ? null
                            : () {
                                context.pushSlidePage(
                                  SupportPage(
                                    initialEmail: _emailController.text.trim(),
                                  ),
                                );
                              },
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                        child: Text(
                          'Algum problema? Contate o suporte',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.action500,
                            fontWeight: FontWeight.w700,
                          ),
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
