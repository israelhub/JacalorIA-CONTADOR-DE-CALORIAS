import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.controller,
    this.onChanged,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.foodReviewFieldBorder),
        boxShadow: AppShadows.foodReviewField,
      ),
      clipBehavior: Clip.antiAlias,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        textAlign: textAlign,
        textAlignVertical: TextAlignVertical.center,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        expands: true,
        maxLines: null,
        minLines: null,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: contentPadding,
        ),
      ),
    );
  }
}

class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.onTap,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.suffixIcon,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    if (validator != null) {
      return _buildWithValidation();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: AppSpacing.sm),
        _buildContainer(
          child: _buildTextField(onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildWithValidation() {
    return FormField<String>(
      initialValue: controller?.text ?? '',
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(),
            const SizedBox(height: AppSpacing.sm),
            _buildContainer(
              child: _buildTextField(onChanged: state.didChange),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  top: AppSpacing.xs,
                ),
                child: Text(
                  state.errorText!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textError,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLabel() {
    return Text(
      label,
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowButtonAlt,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      onTap: onTap,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.surface,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.surface,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.surface,
            width: 1,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.surface,
            width: 1,
          ),
        ),
      ),
    );
  }
}
