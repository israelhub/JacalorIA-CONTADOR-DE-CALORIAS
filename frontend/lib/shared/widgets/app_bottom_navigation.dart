import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/app_theme.dart';
import 'app_nav_icons.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.onCenterActionTap,
    this.surfaceKey = const ValueKey('app-bottom-nav-surface'),
    this.contentKey = const ValueKey('app-bottom-nav-content'),
    this.centerActionKey = const ValueKey('app-bottom-nav-center-action'),
    this.surfaceHeight = appBottomNavCardHeight,
    this.cameraButtonSize = appBottomNavCameraSize,
    this.contentHorizontalPadding = 0,
    this.includeBottomSafeArea = true,
    this.showTopBorder = true,
    this.backgroundColor = AppColors.surface,
  }) : assert(items.length == 4);

  final List<Widget> items;
  final VoidCallback onCenterActionTap;
  final Key surfaceKey;
  final Key contentKey;
  final Key centerActionKey;
  final double surfaceHeight;
  final double cameraButtonSize;
  final double contentHorizontalPadding;
  final bool includeBottomSafeArea;
  final bool showTopBorder;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bottomInset = includeBottomSafeArea
        ? MediaQuery.viewPaddingOf(context).bottom
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTopBorder) const _TopBorderSegment(),
        Container(
          key: surfaceKey,
          height: surfaceHeight + bottomInset,
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(color: backgroundColor),
          child: Padding(
            key: contentKey,
            padding: EdgeInsets.symmetric(horizontal: contentHorizontalPadding),
            child: Row(
              children: [
                Expanded(child: Center(child: items[0])),
                Expanded(child: Center(child: items[1])),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: cameraButtonSize,
                      height: cameraButtonSize,
                      child: _PressableCenterActionButton(
                        key: centerActionKey,
                        onTap: onCenterActionTap,
                        size: cameraButtonSize,
                      ),
                    ),
                  ),
                ),
                Expanded(child: Center(child: items[2])),
                Expanded(child: Center(child: items[3])),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

const double appBottomNavCameraSize = AppSpacing.huge + AppSpacing.sm;

const double appBottomNavCardHeight =
    AppSpacing.huge + AppSpacing.xl + AppSpacing.sm;

const double appBottomNavHorizontalInset = AppSpacing.xxxl;

class _TopBorderSegment extends StatelessWidget {
  const _TopBorderSegment();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderBrandAlt,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class AppBottomNavigationItem extends StatelessWidget {
  const AppBottomNavigationItem({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.iconKey,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Key? iconKey;

  static const double _iconSize = AppSpacing.xxxl;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PhosphorIcon(
        icon,
        key: iconKey,
        size: _iconSize,
        color: color,
      ),
    );
  }
}

class _PressableCenterActionButton extends StatefulWidget {
  const _PressableCenterActionButton({
    super.key,
    required this.onTap,
    required this.size,
  });

  final VoidCallback onTap;
  final double size;

  @override
  State<_PressableCenterActionButton> createState() =>
      _PressableCenterActionButtonState();
}

class _PressableCenterActionButtonState
    extends State<_PressableCenterActionButton> {
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
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : (_isHovered ? 1.05 : 1),
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.brand900 : AppColors.action500,
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              AppNavIcons.camera,
              color: AppColors.surface,
              size: AppSpacing.xxxl,
            ),
          ),
        ),
      ),
    );
  }
}
