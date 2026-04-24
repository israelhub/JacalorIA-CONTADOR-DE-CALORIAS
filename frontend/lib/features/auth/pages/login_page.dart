import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_button.dart';
import 'package:jacaloria/shared/widgets/app_input.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxxl),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: AppSpacing.huge * 4 + AppSpacing.xl,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                AppInputField(
                  label: 'E-mail',
                  hint: 'Digite seu email',
                  controller: _emailController,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppInputField(
                  label: 'Senha',
                  hint: 'Digite sua senha',
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                SizedBox(
                  height: AppSpacing.huge + AppSpacing.xs,
                  child: AppButton(
                    label: 'Entrar',
                    onPressed: () {},
                    variant: AppButtonVariant.primary,
                  ),
                ),
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
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
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
        ),
      ),
    );
  }
}
