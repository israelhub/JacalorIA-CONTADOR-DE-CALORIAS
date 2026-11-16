import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleIcon,
    this.trailing,
    this.titleStyle,
    this.subtitleStyle,
    this.subtitleColor,
  });

  final String title;
  final String? subtitle;
  final IconData? subtitleIcon;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final resolvedTitleStyle =
        titleStyle ?? AppTextStyles.performanceSectionTitle;
    final resolvedSubtitleColor =
        subtitleColor ?? AppColors.brand900Variant;
    final resolvedSubtitleStyle =
        (subtitleStyle ??
                resolvedTitleStyle.copyWith(
                  fontSize: 14,
                  height: 20 / 14,
                ))
            .copyWith(color: resolvedSubtitleColor);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: resolvedTitleStyle,
          ),
        ),
        if (subtitle != null) ...<Widget>[
          if (subtitleIcon != null) ...<Widget>[
            Icon(
              subtitleIcon,
              size: 14,
              color: resolvedSubtitleColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            subtitle!,
            style: resolvedSubtitleStyle,
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
