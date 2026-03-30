import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    super.key,
    required this.activeStep,
    required this.onBack,
    this.totalSteps = 3,
  }) : assert(activeStep >= 1),
       assert(totalSteps >= 1),
       assert(activeStep <= totalSteps);

  final int activeStep;
  final int totalSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.huge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: const Offset(-AppSpacing.lg, 0),
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                color: AppColors.brand900,
                splashRadius: AppSpacing.xl,
              ),
            ),
          ),
          SizedBox(
            width: AppSpacing.huge * 7,
            child: Row(
              children: List.generate(totalSteps * 2 - 1, (index) {
                if (index.isOdd) {
                  return const SizedBox(width: AppSpacing.sm);
                }

                final stepIndex = (index ~/ 2) + 1;
                return Expanded(
                  child: Container(
                    height: AppSpacing.xs,
                    decoration: BoxDecoration(
                      color: stepIndex == activeStep
                          ? AppColors.brand900
                          : AppColors.borderAlt,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
