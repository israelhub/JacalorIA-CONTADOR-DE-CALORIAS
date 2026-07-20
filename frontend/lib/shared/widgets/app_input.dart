import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
    this.contentPadding,
    this.isCollapsed = false,
    this.centerContent = false,
    this.textAlignVertical = TextAlignVertical.center,
  });

  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final bool isCollapsed;
  final bool centerContent;
  final TextAlignVertical textAlignVertical;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textSecondary,
        ),
        border: InputBorder.none,
        contentPadding: contentPadding,
        isCollapsed: isCollapsed,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.foodReviewFieldBorder),
        boxShadow: AppShadows.foodReviewField,
      ),
      child: centerContent ? Center(child: field) : field,
    );
  }
}

class AppInputField extends StatefulWidget {
  const AppInputField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.showPasswordVisibilityToggle = true,
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
  final bool showPasswordVisibilityToggle;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AppInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _isObscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.validator != null) {
      return _buildWithValidation();
    }

    final showLabel = widget.label.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          _buildLabel(),
          const SizedBox(height: AppSpacing.sm),
        ],
        _buildContainer(child: _buildTextField(onChanged: widget.onChanged)),
      ],
    );
  }

  Widget _buildWithValidation() {
    final showLabel = widget.label.trim().isNotEmpty;

    return FormField<String>(
      initialValue: widget.controller?.text ?? '',
      validator: widget.validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLabel) ...[
              _buildLabel(),
              const SizedBox(height: AppSpacing.sm),
            ],
            _buildContainer(child: _buildTextField(onChanged: state.didChange)),
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
      widget.label,
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

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    if (widget.obscureText && widget.showPasswordVisibilityToggle) {
      return IconButton(
        onPressed: () => setState(() => _isObscured = !_isObscured),
        color: AppColors.textSecondary,
        icon: Icon(
          _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      );
    }

    return null;
  }

  Widget _buildTextField({ValueChanged<String>? onChanged}) {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText && _isObscured,
      onTap: widget.onTap,
      onChanged: onChanged,
      keyboardType: widget.keyboardType,
      textAlignVertical: TextAlignVertical.center,
      inputFormatters: widget.inputFormatters,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: _buildSuffixIcon(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
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
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
      ),
    );
  }
}
