import 'package:flutter/material.dart';

import 'activity_level_page.dart';
import '../widgets/onboarding_select_option_button.dart';
import '../widgets/onboarding_step_header.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';

enum ObjectiveType { loseWeight, gainMass, maintainWeight }

class ObjectivePage extends StatefulWidget {
  const ObjectivePage({super.key});

  @override
  State<ObjectivePage> createState() => _ObjectivePageState();
}

class _ObjectivePageState extends State<ObjectivePage> {
  ObjectiveType _selectedObjective = ObjectiveType.loseWeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              OnboardingStepHeader(
                activeStep: 2,
                onBack: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'Qual seu objetivo?',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.huge + AppSpacing.lg),
              OnboardingSelectOptionButton(
                key: const ValueKey('objective-option-lose'),
                boxKey: const ValueKey('objective-option-box-lose'),
                label: 'Emagrecer',
                isSelected: _selectedObjective == ObjectiveType.loseWeight,
                height: AppSpacing.huge + AppSpacing.xs / 2,
                textStyle: AppTextStyles.buttonSmall,
                onTap: () {
                  setState(() {
                    _selectedObjective = ObjectiveType.loseWeight;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              OnboardingSelectOptionButton(
                key: const ValueKey('objective-option-gain'),
                boxKey: const ValueKey('objective-option-box-gain'),
                label: 'Ganhar massa',
                isSelected: _selectedObjective == ObjectiveType.gainMass,
                height: AppSpacing.huge + AppSpacing.xs / 2,
                textStyle: AppTextStyles.buttonSmall,
                onTap: () {
                  setState(() {
                    _selectedObjective = ObjectiveType.gainMass;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              OnboardingSelectOptionButton(
                key: const ValueKey('objective-option-maintain'),
                boxKey: const ValueKey('objective-option-box-maintain'),
                label: 'Manter peso',
                isSelected: _selectedObjective == ObjectiveType.maintainWeight,
                height: AppSpacing.huge + AppSpacing.xs / 2,
                textStyle: AppTextStyles.buttonSmall,
                onTap: () {
                  setState(() {
                    _selectedObjective = ObjectiveType.maintainWeight;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.huge),
              SizedBox(
                key: const ValueKey('objective-next-button-box'),
                width: double.infinity,
                height: AppSpacing.huge + AppSpacing.xs,
                child: AppButton(
                  label: 'Avançar',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ActivityLevelPage(),
                      ),
                    );
                  },
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
