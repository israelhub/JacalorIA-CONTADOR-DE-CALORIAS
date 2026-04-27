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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }

  Color _tabColor(AppMainBottomTab tab) {
    return activeTab == tab ? AppColors.action500 : AppColors.divider;
  }
}
