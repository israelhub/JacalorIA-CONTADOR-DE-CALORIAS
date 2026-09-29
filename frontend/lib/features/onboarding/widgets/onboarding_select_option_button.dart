import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class OnboardingSelectOptionButton extends StatefulWidget {
  const OnboardingSelectOptionButton({
    super.key,
    required this.boxKey,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.height,
    required this.textStyle,
    this.unselectedTextColor = AppColors.brand900,
  });

  final Key boxKey;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double height;
  final TextStyle textStyle;
  final Color unselectedTextColor;

  @override
  State<OnboardingSelectOptionButton> createState() =>
      _OnboardingSelectOptionButtonState();
}

class _OnboardingSelectOptionButtonState
    extends State<OnboardingSelectOptionButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }
    setState(() {
      _isHovered = value;
    });
  }

  Future<void> _handleTap() async {
    _setPressed(true);
    widget.onTap();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) {
      return;
    }
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) {},
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.02 : 1),
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            key: widget.boxKey,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.brand900
                  : (_isHovered ? AppColors.surfaceAlt : AppColors.surface),
              border: Border.all(color: AppColors.brand900, width: 2),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: SizedBox(
              width: double.infinity,
              height: widget.height,
              child: Center(
                child: Text(
                  widget.label,
                  style: widget.textStyle.copyWith(
                    color: widget.isSelected
                        ? AppColors.surface
                        : widget.unselectedTextColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
