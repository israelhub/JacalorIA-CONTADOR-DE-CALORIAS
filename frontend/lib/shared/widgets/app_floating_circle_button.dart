import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Circular floating action button used on Profile (edit pencil) and elsewhere.
class AppFloatingCircleButton extends StatefulWidget {
  const AppFloatingCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.badgeCount,
    this.size = 56,
    this.iconSize = 26,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? semanticLabel;
  final int? badgeCount;
  final double size;
  final double iconSize;

  @override
  State<AppFloatingCircleButton> createState() =>
      _AppFloatingCircleButtonState();
}

class _AppFloatingCircleButtonState extends State<AppFloatingCircleButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() => _isPressed = value);
  }

  String get _badgeLabel {
    final count = widget.badgeCount ?? 0;
    if (count <= 0) {
      return '';
    }
    return count > 99 ? '99+' : count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badgeLabel;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          offset: Offset(0, _isPressed ? 0.012 : 0),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutBack,
            scale: _isPressed ? 0.965 : 1,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: const BoxDecoration(
                      color: AppColors.action500,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.action500Shadow,
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: widget.iconSize,
                    ),
                  ),
                  if (badge.isNotEmpty)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: badge.length > 1 ? 5 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand900Variant,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badge,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.captionStrong.copyWith(
                            color: AppColors.surface,
                            height: 1,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
