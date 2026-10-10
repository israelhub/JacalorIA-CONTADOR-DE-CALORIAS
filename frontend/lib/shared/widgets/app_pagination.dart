import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppPagination extends StatelessWidget {
  const AppPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    this.enabled = true,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canGoPrevious = enabled && page > 1;
    final canGoNext = enabled && page < totalPages;

    return Row(
      children: [
        _AppPaginationIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: canGoPrevious ? () => onPageChanged(page - 1) : null,
        ),
        Expanded(
          child: Text(
            '$page / $totalPages',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.brand900Variant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _AppPaginationIconButton(
          icon: Icons.chevron_right_rounded,
          onTap: canGoNext ? () => onPageChanged(page + 1) : null,
        ),
      ],
    );
  }
}

class _AppPaginationIconButton extends StatelessWidget {
  const _AppPaginationIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: AppColors.insetSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: enabled ? AppColors.brand900Variant : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
