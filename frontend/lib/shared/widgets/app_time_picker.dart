import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Abre o seletor de horário do Material com o visual do app
/// (verdes da marca no lugar do roxo padrão do Material 3).
Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? helpText,
}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: helpText,
    builder: (context, child) {
      final base = Theme.of(context);
      // Força 24h: no formato 12h do sistema, digitar 18/19 falha a validação
      // ("horário não permitido") mesmo com locale pt_BR.
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: AppColors.action500,
              onPrimary: AppColors.surface,
              secondary: AppColors.action500,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
              surfaceTint: Colors.transparent,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md * 2),
              ),
              helpTextStyle: AppTextStyles.captionStrong.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              // Campos de hora/minuto.
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              hourMinuteColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.brand300
                    : AppColors.surfaceAlt,
              ),
              hourMinuteTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.brand900
                    : AppColors.textPrimary,
              ),
              hourMinuteTextStyle: AppTextStyles.headingMedium,
              // Relógio.
              dialBackgroundColor: AppColors.homeProgressTrack,
              dialHandColor: AppColors.action500,
              dialTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.surface
                    : AppColors.textPrimary,
              ),
              dialTextStyle: AppTextStyles.bodyMedium,
              entryModeIconColor: AppColors.brand900,
              // Campo de digitação (modo teclado).
              timeSelectorSeparatorColor: WidgetStatePropertyAll(
                AppColors.textPrimary,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.action500,
                    width: 2,
                  ),
                ),
              ),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                textStyle: AppTextStyles.buttonSmall,
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: AppColors.brand900,
                textStyle: AppTextStyles.buttonSmall,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand900,
                textStyle: AppTextStyles.buttonSmall,
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      );
    },
  );
}
