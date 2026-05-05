import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    required this.icon,
    this.titleStyle,
    this.iconSize = 28,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final TextStyle? titleStyle;
  final double iconSize;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style:
                titleStyle ??
                AppTextStyles.missionsTitle.copyWith(
                  color: AppColors.brand900Variant,
                ),
          ),
        ),
        if (trailing != null) trailing!,
        if (trailing != null) const SizedBox(width: AppSpacing.sm),
        Icon(
          icon,
          size: iconSize,
          color: AppColors.brand900Variant,
        ),
      ],
    );
  }
}
