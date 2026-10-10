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

  void _closeMoreMenu() {
    if (!_isMoreMenuOpen) {
      return;
    }
    setState(() {
      _isMoreMenuOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = HomeShellPage.maybeController;
    if (shell == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: shell.navigationListenable,
      builder: (context, _) {
        return AppMainBottomNavigation(
          activeTab: shell.activeTab,
          overlayDestination: shell.overlayDestination,
          isMoreMenuOpen: _isMoreMenuOpen,
          onMoreTap: () {
            setState(() {
              _isMoreMenuOpen = !_isMoreMenuOpen;
            });
          },
          onCenterActionTap: () {
            _closeMoreMenu();
            unawaited(shell.openFoodCapture());
          },
          onPerformanceTap: () {
            _closeMoreMenu();
            unawaited(shell.openTab(AppMainBottomTab.performance));
          },
          onWorkoutTap: () {
            _closeMoreMenu();
            unawaited(shell.openTab(AppMainBottomTab.workout));
          },
          onNotificationsTap: () {
            _closeMoreMenu();
            unawaited(shell.openNotifications());
          },
          onRemindersTap: () {
            _closeMoreMenu();
            unawaited(shell.openReminders());
          },
          onSupportTap: () {
            _closeMoreMenu();
            unawaited(shell.openSupport());
          },
          onStoreTap: () {
            _closeMoreMenu();
            unawaited(shell.openStore());
          },
          onProfileTap: () {
            _closeMoreMenu();
            unawaited(shell.openProfile());
          },
          onHomeTap: () {
            _closeMoreMenu();
            unawaited(shell.openTab(AppMainBottomTab.home));
          },
          onMissionsTap: () {
            _closeMoreMenu();
            unawaited(shell.openTab(AppMainBottomTab.missions));
          },
          onSocialTap: () {
            _closeMoreMenu();
            unawaited(shell.openTab(AppMainBottomTab.social));
          },
        );
      },
    );
  }
}
