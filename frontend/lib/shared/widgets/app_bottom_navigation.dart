import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.onCenterActionTap,
    this.surfaceKey = const ValueKey('app-bottom-nav-surface'),
    this.contentKey = const ValueKey('app-bottom-nav-content'),
    this.centerActionKey = const ValueKey('app-bottom-nav-center-action'),
    this.surfaceHeight = 56,
    this.cameraButtonSize = AppSpacing.huge + AppSpacing.xl,
    this.cameraOverlap = AppSpacing.xs,
    this.contentHorizontalPadding = 0,
  }) : assert(items.length == 4);

  final List<Widget> items;
  final VoidCallback onCenterActionTap;
  final Key surfaceKey;
  final Key contentKey;
  final Key centerActionKey;
  final double surfaceHeight;
  final double cameraButtonSize;
  final double cameraOverlap;
  final double contentHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final centerSlotWidth = cameraButtonSize;

    return SizedBox(
      height: surfaceHeight + cameraOverlap + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              key: surfaceKey,
              height: surfaceHeight + bottomPadding,
              padding: EdgeInsets.only(bottom: bottomPadding),
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Stack(
                children: [
                  // Linha superior dividida para "abraçar" o botão central.
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.borderBrandAlt,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: centerSlotWidth),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.borderBrandAlt,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    key: contentKey,
                    padding: EdgeInsets.symmetric(
                      horizontal: contentHorizontalPadding,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: Center(child: items[0])),
                              Expanded(child: Center(child: items[1])),
                            ],
                          ),
                        ),
                        SizedBox(width: centerSlotWidth),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: Center(child: items[2])),
                              Expanded(child: Center(child: items[3])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -8,
            child: GestureDetector(
              key: centerActionKey,
              onTap: onCenterActionTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: cameraButtonSize,
                height: cameraButtonSize,
                decoration: const BoxDecoration(
                  color: AppColors.action500,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.surface,
                  size: AppSpacing.xxxl,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppBottomNavigationItem extends StatelessWidget {
  const AppBottomNavigationItem({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.color,
    this.labelKey,
    this.iconKey,
  });

  final String label;
  final String iconAsset;
  final Color color;
  final Key? labelKey;
  final Key? iconKey;

  static const double _iconSize = AppSpacing.xxl + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          iconAsset,
          key: iconKey,
          width: _iconSize,
          height: _iconSize,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          key: labelKey,
          style: AppTextStyles.homeBottomNav.copyWith(color: color, height: 1),
        ),
      ],
    );
  }
}
