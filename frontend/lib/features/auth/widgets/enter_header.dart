import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class EnterHeader extends StatelessWidget {
  const EnterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.huge,
        left: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vamos começar',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
          Text(
            'Construa hábitos saudáveis todos os dias',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
