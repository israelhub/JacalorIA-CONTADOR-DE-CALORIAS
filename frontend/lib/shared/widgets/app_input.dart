import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

abstract final class AppInputStyles {
  static const EdgeInsets singleLineContentPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.lg,
  );

  static double get singleLineHeight =>
      singleLineContentPadding.vertical + 22;

  static TextStyle get value => AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get hint => AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w400,
        height: 1.2,
      );
}

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.onTap,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
    this.contentPadding,
    this.isCollapsed = false,
    this.centerContent = false,
    this.textAlignVertical = TextAlignVertical.center,
    this.maxLines = 1,
    this.minLines,
    this.showBorder = true,
    this.showShadow = true,
    this.borderColor,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final bool isCollapsed;
  final bool centerContent;
  final TextAlignVertical textAlignVertical;
  final int? maxLines;
  final int? minLines;
  final bool showBorder;
  final bool showShadow;
  final Color? borderColor;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final Widget? suffixIcon;

  bool get _isMultiline => (maxLines ?? 1) > 1 || (minLines ?? 1) > 1;

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: showBorder ? BorderSide(color: color) : BorderSide.none,
    );
  }

  InputDecoration _decoration({required EdgeInsetsGeometry padding}) {
    final sideColor = borderColor ?? AppColors.inputBorder;
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppInputStyles.hint,
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: padding,
      suffixIcon: suffixIcon,
      border: _border(sideColor),
      enabledBorder: _border(sideColor),
      focusedBorder: _border(sideColor),
      disabledBorder: _border(sideColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = _isMultiline ? _buildMultiline() : _buildSingleLine();

    if (!showShadow) {
      return field;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.foodReviewField,
      ),
      child: field,
    );
  }

  Widget _buildSingleLine() {
    final padding = contentPadding ?? AppInputStyles.singleLineContentPadding;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      onTap: onTap,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textAlign: centerContent ? TextAlign.center : textAlign,
      textAlignVertical: TextAlignVertical.center,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      cursorColor: AppColors.brand900,
      style: AppInputStyles.value,
      maxLines: 1,
      decoration: _decoration(padding: padding),
    );
  }

  Widget _buildMultiline() {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      cursorColor: AppColors.brand900,
      style: AppInputStyles.value,
      decoration: _decoration(
        padding: contentPadding ?? const EdgeInsets.all(AppSpacing.md),
      ),
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
    this.textCapitalization = TextCapitalization.none,
    this.showShadow = false,
    this.borderColor = AppColors.inputBorder,
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
  final TextCapitalization textCapitalization;
  final bool showShadow;
  final Color borderColor;

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  late bool _isObscured;
  TextEditingController? _fallbackController;

  TextEditingController get _controller =>
      widget.controller ?? (_fallbackController ??= TextEditingController());

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
  void dispose() {
    _fallbackController?.dispose();
    super.dispose();
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
        _buildInput(onChanged: widget.onChanged),
      ],
    );
  }

  Widget _buildWithValidation() {
    final showLabel = widget.label.trim().isNotEmpty;

    return FormField<String>(
      initialValue: _controller.text,
      validator: widget.validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLabel) ...[
              _buildLabel(),
              const SizedBox(height: AppSpacing.sm),
            ],
            _buildInput(onChanged: (value) {
              state.didChange(value);
              widget.onChanged?.call(value);
            }),
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

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    if (widget.obscureText && widget.showPasswordVisibilityToggle) {
      return IconButton(
        onPressed: () => setState(() => _isObscured = !_isObscured),
        color: AppColors.textSecondary,
        icon: Icon(
          _isObscured
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      );
    }

    return null;
  }

  Widget _buildInput({ValueChanged<String>? onChanged}) {
    return AppInput(
      controller: _controller,
      hintText: widget.hint,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText && _isObscured,
      onTap: widget.onTap,
      onChanged: onChanged,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.textCapitalization,
      suffixIcon: _buildSuffixIcon(),
      showShadow: widget.showShadow,
      borderColor: widget.borderColor,
    );
  }
}
