import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pull-to-refresh wrapper for main screen scroll content.
///
/// Uses [AlwaysScrollableScrollPhysics] so refresh works even when content
/// is shorter than the viewport (mobile and web overscroll).
class AppRefreshScrollView extends StatelessWidget {
  const AppRefreshScrollView({
    super.key,
    required this.onRefresh,
    required this.child,
    this.padding,
    this.controller,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.action500,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: child,
      ),
    );
  }
}
