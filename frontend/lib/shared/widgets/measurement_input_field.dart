import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'app_input.dart';

class MeasurementInputField extends StatelessWidget {
  const MeasurementInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.selectedUnit,
    required this.unitOptions,
    required this.onUnitSelected,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.unitSelectorKey,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String selectedUnit;
  final List<String> unitOptions;
  final ValueChanged<String> onUnitSelected;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Key? unitSelectorKey;

  @override
  Widget build(BuildContext context) {
    return AppInputField(
      label: label,
      hint: hint,
      controller: controller,
      keyboardType:
          keyboardType ?? const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      suffixIcon: PopupMenuButton<String>(
        key: unitSelectorKey,
        initialValue: selectedUnit,
        padding: EdgeInsets.zero,
        onSelected: onUnitSelected,
        itemBuilder: (context) => unitOptions
            .map(
              (unit) => PopupMenuItem<String>(
                value: unit,
                child: Text(
                  unit,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            )
            .toList(),
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedUnit,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
