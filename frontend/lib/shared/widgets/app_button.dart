import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

enum AppButtonVariant { primary, outline, google, danger, link }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.trailingIcon,
    this.leadingIcon,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? trailingIcon;
  final IconData? leadingIcon;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      AppButtonVariant.primary => _PrimaryButton(
        label: label,
        onPressed: onPressed,
        trailingIcon: trailingIcon,
        leadingIcon: leadingIcon,
        textStyle: textStyle,
      ),
      AppButtonVariant.outline => _OutlineButton(
        label: label,
        onPressed: onPressed,
        trailingIcon: trailingIcon,
        leadingIcon: leadingIcon,
        textStyle: textStyle,
      ),
      AppButtonVariant.google => _GoogleButton(
        label: label,
        onPressed: onPressed,
      ),
      AppButtonVariant.danger => _DangerButton(
        label: label,
        onPressed: onPressed,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
        textStyle: textStyle,
      ),
      AppButtonVariant.link => _LinkButton(
        label: label,
        onPressed: onPressed,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
        textStyle: textStyle,
      ),
    };
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.leadingIcon,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final IconData? leadingIcon;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return _PressableButtonSurface(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.action500,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: const [
            BoxShadow(
              color: AppColors.action500Shadow,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        alignment: Alignment.center,
        child: (leadingIcon == null && trailingIcon == null)
            ? Text(
                label,
                style: (textStyle ?? AppTextStyles.buttonLarge).copyWith(color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, color: Colors.white, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label,
                    style: (textStyle ?? AppTextStyles.buttonLarge).copyWith(
                      color: Colors.white,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(trailingIcon, color: Colors.white, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.leadingIcon,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final IconData? leadingIcon;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return _PressableButtonSurface(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderAlt),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowButtonAlt,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 17),
        alignment: Alignment.center,
        child: (leadingIcon == null && trailingIcon == null)
            ? Text(
                label,
                style: (textStyle ?? AppTextStyles.buttonMedium).copyWith(
                  color: AppColors.action500,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, color: AppColors.action500, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label,
                    style: (textStyle ?? AppTextStyles.buttonMedium).copyWith(
                      color: AppColors.action500,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(trailingIcon, color: AppColors.action500, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _PressableButtonSurface(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowButton,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/google_logo.svg',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final TextStyle? textStyle;

  static const Color _dangerColor = Color(0xFFD32F2F);
  static const Color _dangerShadow = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    return _PressableButtonSurface(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _dangerColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: const [
            BoxShadow(
              color: _dangerShadow,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: (textStyle ?? AppTextStyles.buttonLarge).copyWith(color: Colors.white),
            ),
            if (leadingIcon != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(leadingIcon, color: Colors.white, size: 20),
            ],
            if (trailingIcon != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(trailingIcon, color: Colors.white, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return _PressableButtonSurface(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: AppColors.action500, size: 18),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: (textStyle ?? AppTextStyles.bodyMedium).copyWith(
                color: AppColors.action500,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(trailingIcon, color: AppColors.action500, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _PressableButtonSurface extends StatefulWidget {
  const _PressableButtonSurface({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressableButtonSurface> createState() => _PressableButtonSurfaceState();
}

class _PressableButtonSurfaceState extends State<_PressableButtonSurface> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedSlide(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      offset: Offset(0, _isPressed ? 0.012 : 0),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        scale: _isPressed ? 0.965 : 1,
        child: widget.child,
      ),
    );

    if (widget.onTap == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: content,
    );
  }
}
