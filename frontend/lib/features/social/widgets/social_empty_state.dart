import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class SocialEmptyState extends StatelessWidget {
  const SocialEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.backgroundColor = AppColors.surface,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.action500),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.homeMealTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
