import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppGuideCard extends StatelessWidget {
  const AppGuideCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onClose,
    this.backgroundColor = AppColors.action500,
    this.iconBackgroundColor = AppColors.missionsIntroIcon,
    this.iconColor = AppColors.surface,
    this.titleStyle,
    this.descriptionStyle,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onClose;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.missionsIntro,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style:
                            titleStyle ??
                            AppTextStyles.missionsIntroTitle.copyWith(
                              color: iconColor,
                            ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.close_rounded,
                        size: 24,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style:
                      descriptionStyle ??
                      AppTextStyles.missionsIntroDescription.copyWith(
                        color: iconColor,
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