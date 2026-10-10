import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppFormCard extends StatelessWidget {
  const AppFormCard({super.key, required this.child, this.expand = false});

  final Widget child;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      height: expand ? double.infinity : null,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: child,
    );
    return card;
  }
}
