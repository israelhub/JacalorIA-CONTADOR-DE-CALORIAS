import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_main_bottom_navigation.dart';
import '../pages/home_shell_page.dart';

class HomeShellOverlayNavigationBar extends StatefulWidget {
  const HomeShellOverlayNavigationBar({super.key});

  static bool get isAvailable => HomeShellPage.maybeController != null;

  static Widget? maybeOf() {
    if (!isAvailable) {
      return null;
    }
    return const HomeShellOverlayNavigationBar();
  }

  static Widget wrap({required Widget child}) {
    final nav = maybeOf();
    if (nav == null) {
      return child;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(left: 0, right: 0, bottom: 0, child: nav),
      ],
    );
  }

  @override
  State<HomeShellOverlayNavigationBar> createState() =>
      _HomeShellOverlayNavigationBarState();
}

class _HomeShellOverlayNavigationBarState
    extends State<HomeShellOverlayNavigationBar> {
  bool _isMoreMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final shell = HomeShellPage.maybeController;
    if (shell == null) {
      return const SizedBox.shrink();
    }

    return AppMainBottomNavigation(
      activeTab: shell.activeTab,
      isMoreMenuOpen: _isMoreMenuOpen,
      onMoreTap: () {
        setState(() {
          _isMoreMenuOpen = !_isMoreMenuOpen;
        });
      },
      onCenterActionTap: () {
        setState(() {
          _isMoreMenuOpen = false;
        });
        unawaited(shell.openFoodCapture());
      },
      onPerformanceTap: () {
        setState(() {
          _isMoreMenuOpen = false;
        });
        unawaited(shell.openTab(AppMainBottomTab.performance));
      },
      onWorkoutTap: () {
        setState(() {
          _isMoreMenuOpen = false;
        });
        unawaited(shell.openTab(AppMainBottomTab.workout));
      },
      onNotificationsTap: () {
        setState(() {
          _isMoreMenuOpen = false;
        });
        unawaited(shell.openNotifications());
      },
      onStoreTap: () {
        setState(() {
          _isMoreMenuOpen = false;
        });
        unawaited(shell.openStore());
      },
      onProfileTap: () {
        setState(() {
          _isMoreMenuOpen = false;
        });
        unawaited(shell.openProfile());
      },
      onHomeTap: () {
        setState(() {
          _isMoreMenuOpen = false;
        });
        unawaited(shell.openTab(AppMainBottomTab.home));
      },
      onMissionsTap: () {
        setState(() {
          _isMoreMenuOpen = false;
        });
        unawaited(shell.openTab(AppMainBottomTab.missions));
      },
      onSocialTap: () {
        setState(() {
          _isMoreMenuOpen = false;
        });
        unawaited(shell.openTab(AppMainBottomTab.social));
      },
    );
  }
}
