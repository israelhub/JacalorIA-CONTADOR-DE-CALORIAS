import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class FoodAnalysisPageHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const FoodAnalysisPageHeader({
    super.key,
    required this.title,
    this.backgroundColor = AppColors.surface,
    this.titleColor = AppColors.textPrimary,
    this.leadingIconColor = AppColors.brand900Variant,
    this.actions,
  });

  final String title;
  final Color backgroundColor;
  final Color titleColor;
  final Color leadingIconColor;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      iconTheme: IconThemeData(color: leadingIconColor),
      actions: actions,
      title: Text(
        title,
        style: AppTextStyles.homeSectionTitle.copyWith(
          color: titleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
