import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_modal.dart';
import '../helpers/home_water_helpers.dart';

Future<int?> showHomeAddWaterSheet(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (context) {
      return AppModal(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quanto de água?',
              style: AppTextStyles.missionsSectionTitle.copyWith(
                color: AppColors.brand900Variant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...homeWaterQuickAmountsMl.map(
              (amount) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.water_drop_outlined,
                  color: AppColors.homeWater,
                ),
                title: Text(formatWaterVolume(amount)),
                onTap: () => Navigator.of(context).pop(amount),
              ),
            ),
          ],
        ),
      );
    },
  );
}
