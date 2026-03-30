import 'package:flutter/material.dart';

import 'package:jacaloria/features/onboarding/widgets/onboarding_step_header.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_button.dart';

enum ActivityLevelType { sedentary, lightly, moderate, very, extreme }

class ActivityLevelPage extends StatefulWidget {
  const ActivityLevelPage({super.key});

  @override
  State<ActivityLevelPage> createState() => _ActivityLevelPageState();
}

class _ActivityLevelPageState extends State<ActivityLevelPage> {
  ActivityLevelType _selectedActivityLevel = ActivityLevelType.sedentary;

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
                activeStep: 3,
                onBack: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'Nível de\natividade física',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.huge + AppSpacing.lg),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ListView(
                      children: [
                        _ActivityLevelOptionButton(
                          key: const ValueKey('activity-option-sedentary'),
                          boxKey: const ValueKey(
                            'activity-option-box-sedentary',
                          ),
                          label: 'Sedentário (não pratico exercícios)',
                          isSelected:
                              _selectedActivityLevel ==
                              ActivityLevelType.sedentary,
                          onTap: () {
                            setState(() {
                              _selectedActivityLevel =
                                  ActivityLevelType.sedentary;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ActivityLevelOptionButton(
                          key: const ValueKey('activity-option-lightly'),
                          boxKey: const ValueKey('activity-option-box-lightly'),
                          label: 'Levemente ativo (1-2 dias por semana)',
                          isSelected:
                              _selectedActivityLevel ==
                              ActivityLevelType.lightly,
                          onTap: () {
                            setState(() {
                              _selectedActivityLevel =
                                  ActivityLevelType.lightly;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ActivityLevelOptionButton(
                          key: const ValueKey('activity-option-moderate'),
                          boxKey: const ValueKey(
                            'activity-option-box-moderate',
                          ),
                          label: 'Moderadamente ativo (3-4 dias por semana)',
                          isSelected:
                              _selectedActivityLevel ==
                              ActivityLevelType.moderate,
                          onTap: () {
                            setState(() {
                              _selectedActivityLevel =
                                  ActivityLevelType.moderate;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ActivityLevelOptionButton(
                          key: const ValueKey('activity-option-very'),
                          boxKey: const ValueKey('activity-option-box-very'),
                          label: 'Muito ativo (5-6 dias por semana)',
                          isSelected:
                              _selectedActivityLevel == ActivityLevelType.very,
                          onTap: () {
                            setState(() {
                              _selectedActivityLevel = ActivityLevelType.very;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ActivityLevelOptionButton(
                          key: const ValueKey('activity-option-extreme'),
                          boxKey: const ValueKey('activity-option-box-extreme'),
                          label: 'Extremamente ativo (todos os dias)',
                          isSelected:
                              _selectedActivityLevel ==
                              ActivityLevelType.extreme,
                          onTap: () {
                            setState(() {
                              _selectedActivityLevel =
                                  ActivityLevelType.extreme;
                            });
                          },
                        ),
                      ],
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: (AppSpacing.huge * 2) + AppSpacing.xl,
                        ),
                        child: SizedBox(
                          key: const ValueKey('activity-finish-button-box'),
                          width: double.infinity,
                          height: AppSpacing.huge + AppSpacing.xs,
                          child: AppButton(
                            label: 'Finalizar',
                            onPressed: () {},
                            variant: AppButtonVariant.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityLevelOptionButton extends StatelessWidget {
  const _ActivityLevelOptionButton({
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
      child: Container(
        key: boxKey,
        width: double.infinity,
        height: AppSpacing.huge + AppSpacing.lg,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand900 : AppColors.surface,
          border: Border.all(color: AppColors.brand900, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: isSelected ? AppColors.surface : AppColors.brand900Variant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
