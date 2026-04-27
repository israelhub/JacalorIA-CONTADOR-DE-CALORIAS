import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleStyle,
    this.subtitleStyle,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: titleStyle ?? AppTextStyles.performanceSectionTitle,
          ),
        ),
        if (subtitle != null) ...<Widget>[
          Text(
            subtitle!,
            style: subtitleStyle ?? AppTextStyles.missionsSectionSubtitle,
          ),
        ],
        if (trailing != null) ...<Widget>[
          if (subtitle != null) const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}