import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

enum SocialProfileInfoCardLayout { horizontal, compactStart }

class SocialProfileInfoCard extends StatelessWidget {
  const SocialProfileInfoCard({
    super.key,
    this.iconWidget,
    required this.icon,
    this.iconColor = AppColors.action500,
    required this.label,
    required this.value,
    this.backgroundColor = AppColors.insetSurface,
    this.layout = SocialProfileInfoCardLayout.horizontal,
  });

  final Widget? iconWidget;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color backgroundColor;
  final SocialProfileInfoCardLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: layout == SocialProfileInfoCardLayout.compactStart
          ? Alignment.centerLeft
          : null,
      padding: layout == SocialProfileInfoCardLayout.compactStart
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md + AppSpacing.xs,
            )
          : const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: layout == SocialProfileInfoCardLayout.compactStart
          ? _CompactStartContent(
              iconWidget: iconWidget,
              icon: icon,
              iconColor: iconColor,
              label: label,
              value: value,
            )
          : _HorizontalContent(
              iconWidget: iconWidget,
              icon: icon,
              iconColor: iconColor,
              label: label,
              value: value,
            ),
    );
  }
}

class _HorizontalContent extends StatelessWidget {
  const _HorizontalContent({
    required this.iconWidget,
    required this.icon,
    required this.iconColor,
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
    return Row(
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
    );
  }
}

class _CompactStartContent extends StatelessWidget {
  const _CompactStartContent({
    required this.iconWidget,
    required this.icon,
    required this.iconColor,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        iconWidget ?? Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          style: AppTextStyles.label.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
      ],
    );
  }
}
