import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../widgets/sign_up_form.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              SizedBox(height: AppSpacing.xxl),
              Image(
                image: AssetImage('assets/images/logo.png'),
                height: AppSpacing.huge * 4 + AppSpacing.xl,
                fit: BoxFit.contain,
              ),
              SizedBox(height: AppSpacing.xxl),
              SignUpForm(),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}