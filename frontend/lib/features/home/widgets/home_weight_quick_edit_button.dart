import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class HomeWeightQuickEditButton extends StatelessWidget {
  const HomeWeightQuickEditButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Atualizar peso',
      child: Material(
        elevation: 2,
        color: AppColors.surface,
        shadowColor: AppColors.brand900.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: const BorderSide(color: AppColors.borderBrandAlt, width: 1.2),
        ),
        child: InkWell(
          key: const ValueKey('home-weight-quick-edit-button'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  size: AppSpacing.lg + AppSpacing.xs,
                  color: AppColors.action500,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Peso',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand900Variant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Extra space so the quick-edit chip sits above the shell bottom navigation.
const homeWeightQuickEditBottomClearance =
    AppSpacing.huge + AppSpacing.xxxl + AppSpacing.sm;
