import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class SocialProfileInfoCard extends StatelessWidget {
  const SocialProfileInfoCard({
    super.key,
    this.iconWidget,
    required this.icon,
    this.iconColor = AppColors.action500,
    required this.label,
    required this.value,
  });

  final Widget? iconWidget;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.performanceCardBorder, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget ?? Icon(icon, color: iconColor, size: 26),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
