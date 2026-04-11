import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class OnboardingSelectOptionButton extends StatelessWidget {
  const OnboardingSelectOptionButton({
    super.key,
    required this.boxKey,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.height,
    required this.textStyle,
    this.unselectedTextColor = AppColors.brand900,
  });

  final Key boxKey;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double height;
  final TextStyle textStyle;
  final Color unselectedTextColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        key: boxKey,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand900 : AppColors.surface,
          border: Border.all(color: AppColors.brand900, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Center(
            child: Text(
              label,
              style: textStyle.copyWith(
                color: isSelected ? AppColors.surface : unselectedTextColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
