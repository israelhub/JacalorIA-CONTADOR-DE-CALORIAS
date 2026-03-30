import 'package:flutter/material.dart';

import 'activity_level_page.dart';
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                'Objetivo',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.huge + AppSpacing.xl),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ObjectiveOptionButton(
                      key: const ValueKey('objective-option-lose'),
                      boxKey: const ValueKey('objective-option-box-lose'),
                      label: 'Emagrecer',
                      isSelected:
                          _selectedObjective == ObjectiveType.loseWeight,
                      onTap: () {
                        setState(() {
                          _selectedObjective = ObjectiveType.loseWeight;
                        });
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ObjectiveOptionButton(
                      key: const ValueKey('objective-option-gain'),
                      boxKey: const ValueKey('objective-option-box-gain'),
                      label: 'Ganhar massa',
                      isSelected: _selectedObjective == ObjectiveType.gainMass,
                      onTap: () {
                        setState(() {
                          _selectedObjective = ObjectiveType.gainMass;
                        });
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ObjectiveOptionButton(
                      key: const ValueKey('objective-option-maintain'),
                      boxKey: const ValueKey('objective-option-box-maintain'),
                      label: 'Manter peso',
                      isSelected:
                          _selectedObjective == ObjectiveType.maintainWeight,
                      onTap: () {
                        setState(() {
                          _selectedObjective = ObjectiveType.maintainWeight;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.huge + AppSpacing.huge),
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

class _ObjectiveOptionButton extends StatelessWidget {
  const _ObjectiveOptionButton({
    super.key,
    required this.boxKey,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Key boxKey;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        key: boxKey,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand900 : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.brand900, width: 2),
        ),
        child: SizedBox(
          width: (AppSpacing.huge * 2.7) + AppSpacing.sm,
          height: AppSpacing.huge + AppSpacing.xs / 2,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.buttonSmall.copyWith(
                color: isSelected ? AppColors.surface : AppColors.brand900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
