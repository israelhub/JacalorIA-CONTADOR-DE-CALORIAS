import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _appDatePickerLocale = Locale('pt', 'BR');

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    locale: _appDatePickerLocale,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (context, child) {
      final baseTheme = Theme.of(context);
      final colorScheme = baseTheme.colorScheme.copyWith(
        primary: AppColors.action500,
        onPrimary: AppColors.surface,
        secondary: AppColors.action500,
        onSecondary: AppColors.surface,
        surface: AppColors.surface,
        onSurface: AppColors.brand900Variant,
      );

      return Theme(
        data: baseTheme.copyWith(
          colorScheme: colorScheme,
          datePickerTheme: baseTheme.datePickerTheme.copyWith(
            backgroundColor: AppColors.surface,
            headerBackgroundColor: AppColors.surface,
            headerForegroundColor: AppColors.brand900Variant,
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.black;
              }
              return AppColors.brand900Variant;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.action500;
              }
              return Colors.transparent;
            }),
            todayForegroundColor: const WidgetStatePropertyAll(
              AppColors.surface,
            ),
            todayBackgroundColor: const WidgetStatePropertyAll(
              AppColors.action500,
            ),
            todayBorder: const BorderSide(color: AppColors.action500),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: AppColors.action500,
            ),
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: AppColors.action500,
            ),
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}
