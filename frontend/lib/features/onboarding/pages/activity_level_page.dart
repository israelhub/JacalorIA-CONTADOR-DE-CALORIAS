import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/app_page_route.dart';

import 'package:jacaloria/features/home/pages/home_shell_page.dart';
import 'package:jacaloria/features/onboarding/widgets/onboarding_select_option_button.dart';
import 'package:jacaloria/features/onboarding/widgets/onboarding_step_header.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_button.dart';
import 'package:jacaloria/shared/widgets/app_toast.dart';

import 'package:jacaloria/features/auth/service/auth_service.dart';

enum ActivityLevelType { sedentary, lightly, moderate, very, extreme }

class ActivityLevelPage extends StatefulWidget {
  const ActivityLevelPage({
    super.key,
    this.onboardingData = const {},
    this.authService,
  });

  final Map<String, dynamic> onboardingData;
  final AuthService? authService;

  @override
  State<ActivityLevelPage> createState() => _ActivityLevelPageState();
}

class _ActivityLevelPageState extends State<ActivityLevelPage> {
  static const _newAccountFirstHomeAccessKeyPrefix =
      'new_account_first_home_access_';
  ActivityLevelType _selectedActivityLevel = ActivityLevelType.sedentary;
  bool _isLoading = false;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  Future<void> _submitAndFinish() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = Map<String, dynamic>.from(widget.onboardingData);
      data['activityLevel'] = _selectedActivityLevel.name;

      await _authService.updateProfile(data);
      await _markFirstHomeAccessForCurrentUser();

      if (mounted) {
        context.pushAndRemoveUntilSlidePage(
          HomeShellPage.fromLaunch(),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppToast.error(context, message: 'Erro ao salvar dados: $e');
      }
    }
  }

  Future<void> _markFirstHomeAccessForCurrentUser() async {
    final user = AuthService.globalUser;
    if (user == null) {
      return;
    }

    final rawUserId = user['id'] ?? user['email'] ?? user['name'] ?? '';
    final userId = rawUserId.toString().trim();
    if (userId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_newAccountFirstHomeAccessKeyPrefix$userId', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              OnboardingStepHeader(
                activeStep: 3,
                onBack: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'Qual seu nível de atividade física?',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.huge + AppSpacing.lg),
              OnboardingSelectOptionButton(
                key: const ValueKey('activity-option-sedentary'),
                boxKey: const ValueKey('activity-option-box-sedentary'),
                label: 'Sedentário (não pratico exercícios)',
                isSelected:
                    _selectedActivityLevel == ActivityLevelType.sedentary,
                height: AppSpacing.huge + AppSpacing.lg,
                textStyle: AppTextStyles.label,
                unselectedTextColor: AppColors.brand900Variant,
                onTap: () {
                  setState(() {
                    _selectedActivityLevel = ActivityLevelType.sedentary;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              OnboardingSelectOptionButton(
                key: const ValueKey('activity-option-lightly'),
                boxKey: const ValueKey('activity-option-box-lightly'),
                label: 'Levemente ativo (1-2 dias por semana)',
                isSelected: _selectedActivityLevel == ActivityLevelType.lightly,
                height: AppSpacing.huge + AppSpacing.lg,
                textStyle: AppTextStyles.label,
                unselectedTextColor: AppColors.brand900Variant,
                onTap: () {
                  setState(() {
                    _selectedActivityLevel = ActivityLevelType.lightly;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              OnboardingSelectOptionButton(
                key: const ValueKey('activity-option-moderate'),
                boxKey: const ValueKey('activity-option-box-moderate'),
                label: 'Moderadamente ativo (3-4 dias por semana)',
                isSelected:
                    _selectedActivityLevel == ActivityLevelType.moderate,
                height: AppSpacing.huge + AppSpacing.lg,
                textStyle: AppTextStyles.label,
                unselectedTextColor: AppColors.brand900Variant,
                onTap: () {
                  setState(() {
                    _selectedActivityLevel = ActivityLevelType.moderate;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              OnboardingSelectOptionButton(
                key: const ValueKey('activity-option-very'),
                boxKey: const ValueKey('activity-option-box-very'),
                label: 'Muito ativo (5-6 dias por semana)',
                isSelected: _selectedActivityLevel == ActivityLevelType.very,
                height: AppSpacing.huge + AppSpacing.lg,
                textStyle: AppTextStyles.label,
                unselectedTextColor: AppColors.brand900Variant,
                onTap: () {
                  setState(() {
                    _selectedActivityLevel = ActivityLevelType.very;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              OnboardingSelectOptionButton(
                key: const ValueKey('activity-option-extreme'),
                boxKey: const ValueKey('activity-option-box-extreme'),
                label: 'Extremamente ativo (todos os dias)',
                isSelected: _selectedActivityLevel == ActivityLevelType.extreme,
                height: AppSpacing.huge + AppSpacing.lg,
                textStyle: AppTextStyles.label,
                unselectedTextColor: AppColors.brand900Variant,
                onTap: () {
                  setState(() {
                    _selectedActivityLevel = ActivityLevelType.extreme;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.huge),
              SizedBox(
                key: const ValueKey('activity-finish-button-box'),
                width: double.infinity,
                height: AppSpacing.huge + AppSpacing.xs,
                child: AppButton(
                  label: _isLoading ? 'Salvando...' : 'Finalizar',
                  onPressed: _isLoading ? null : _submitAndFinish,
                  variant: AppButtonVariant.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
