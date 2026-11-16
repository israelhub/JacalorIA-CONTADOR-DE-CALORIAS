import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_bottom_navigation.dart';

enum AppMainBottomTab { performance, home, missions, social }

class AppMainBottomNavigation extends StatelessWidget {
  const AppMainBottomNavigation({
    super.key,
    required this.activeTab,
    required this.onCenterActionTap,
    this.onPerformanceTap,
    this.onHomeTap,
    this.onMissionsTap,
    this.onSocialTap,
  });

  final AppMainBottomTab activeTab;
  final VoidCallback onCenterActionTap;
  final VoidCallback? onPerformanceTap;
  final VoidCallback? onHomeTap;
  final VoidCallback? onMissionsTap;
  final VoidCallback? onSocialTap;

  @override
  Widget build(BuildContext context) {
    return AppBottomNavigation(
      items: [
        _buildTabItem(
          onTap: onPerformanceTap,
          child: AppBottomNavigationItem(
            label: 'Desempenho',
            iconAsset: 'assets/icons/calendar.svg',
            color: _tabColor(AppMainBottomTab.performance),
          ),
        ),
        _buildTabItem(
          onTap: onHomeTap,
          child: AppBottomNavigationItem(
            label: 'Inicio',
            iconAsset: 'assets/icons/home.svg',
            color: _tabColor(AppMainBottomTab.home),
          ),
        ),
        _buildTabItem(
          onTap: onMissionsTap,
          child: AppBottomNavigationItem(
            label: 'Missões',
            iconAsset: 'assets/icons/mission.svg',
            color: _tabColor(AppMainBottomTab.missions),
          ),
        ),
        _buildTabItem(
          onTap: onSocialTap,
          child: AppBottomNavigationItem(
            label: 'Social',
            iconAsset: 'assets/icons/profile.svg',
            color: _tabColor(AppMainBottomTab.social),
          ),
        ),
      ],
      onCenterActionTap: onCenterActionTap,
    );
  }

  Widget _buildTabItem({required Widget child, VoidCallback? onTap}) {
    return _PressableMainNavItem(onTap: onTap, child: child);
  }

  Color _tabColor(AppMainBottomTab tab) {
    return activeTab == tab ? AppColors.action500 : AppColors.divider;
  }
}

class _PressableMainNavItem extends StatefulWidget {
  const _PressableMainNavItem({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressableMainNavItem> createState() => _PressableMainNavItemState();
}

class _PressableMainNavItemState extends State<_PressableMainNavItem> {
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
    if (widget.onTap == null) {
      return;
    }
    _setPressed(true);
    widget.onTap!.call();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) {
      return;
    }
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) {},
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed
              ? 0.94
              : (_isHovered && widget.onTap != null ? 1.05 : 1),
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
