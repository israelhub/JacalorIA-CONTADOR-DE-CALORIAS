import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class ProfilePrivacyCard extends StatelessWidget {
  const ProfilePrivacyCard({
    super.key,
    required this.mealsVisible,
    required this.busy,
    required this.onMealsVisibleChanged,
  });

  final bool mealsVisible;
  final bool busy;
  final ValueChanged<bool> onMealsVisibleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacidade',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.insetSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Mostrar refeições no perfil público',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.brand900Variant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.86,
                child: Switch(
                  value: mealsVisible,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeThumbColor: AppColors.surface,
                  activeTrackColor: AppColors.action500,
                  inactiveThumbColor: AppColors.textMuted,
                  inactiveTrackColor: AppColors.surfaceAlt,
                  onChanged: busy ? null : onMealsVisibleChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
