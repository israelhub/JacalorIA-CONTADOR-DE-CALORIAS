import 'package:flutter/material.dart';

import '../../../shared/widgets/app_back_page_header.dart';

class FoodAnalysisPageHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const FoodAnalysisPageHeader({
    super.key,
    required this.title,
    this.backgroundColor = Colors.transparent,
    this.actions,
  });

  final String title;
  final Color backgroundColor;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const AppBackPageHeader(title: '').preferredSize;

  @override
  Widget build(BuildContext context) {
    return AppBackPageHeader(
      title: title,
      backgroundColor: backgroundColor,
      actions: actions ?? const <Widget>[],
    );
  }
}
