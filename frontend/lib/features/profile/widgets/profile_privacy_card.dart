import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class ProfilePrivacyCard extends StatelessWidget {
  const ProfilePrivacyCard({
    super.key,
    required this.mealsVisible,
    required this.workoutsVisible,
    required this.analyticsEnabled,
    required this.busy,
    required this.onMealsVisibleChanged,
    required this.onWorkoutsVisibleChanged,
    required this.onAnalyticsEnabledChanged,
    this.showTitle = true,
  });

  final bool mealsVisible;
  final bool workoutsVisible;
  final bool analyticsEnabled;
  final bool busy;
  final ValueChanged<bool> onMealsVisibleChanged;
  final ValueChanged<bool> onWorkoutsVisibleChanged;
  final ValueChanged<bool> onAnalyticsEnabledChanged;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final switches = Column(
      children: [
        _PrivacySwitchRow(
          label: 'Mostrar refeições no perfil público',
          value: mealsVisible,
          busy: busy,
          onChanged: onMealsVisibleChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(height: 1, color: AppColors.inputBorder),
        const SizedBox(height: AppSpacing.md),
        _PrivacySwitchRow(
          label: 'Mostrar treinos no perfil público',
          value: workoutsVisible,
          busy: busy,
          onChanged: onWorkoutsVisibleChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(height: 1, color: AppColors.inputBorder),
        const SizedBox(height: AppSpacing.md),
        _PrivacySwitchRow(
          label: 'Permitir analytics de uso',
          value: analyticsEnabled,
          busy: busy,
          onChanged: onAnalyticsEnabledChanged,
        ),
      ],
    );

    if (!showTitle) {
      return switches;
    }

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
        switches,
      ],
    );
  }
}

class _PrivacySwitchRow extends StatelessWidget {
  const _PrivacySwitchRow({
    required this.label,
    required this.value,
    required this.busy,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.brand900Variant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Transform.scale(
          scale: 0.86,
          child: Switch(
            value: value,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeThumbColor: AppColors.surface,
            activeTrackColor: AppColors.action500,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surfaceAlt,
            onChanged: busy ? null : onChanged,
          ),
        ),
      ],
    );
  }
}
