import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_main_bottom_navigation.dart';
import '../pages/home_shell_page.dart';

class HomeShellOverlayNavigationBar extends StatelessWidget {
  const HomeShellOverlayNavigationBar({super.key});

  static bool get isAvailable => HomeShellPage.maybeController != null;

  static Widget? maybeOf() {
    if (!isAvailable) {
      return null;
    }
    return const HomeShellOverlayNavigationBar();
  }

  @override
  Widget build(BuildContext context) {
    final shell = HomeShellPage.maybeController;
    if (shell == null) {
      return const SizedBox.shrink();
    }

    return AppMainBottomNavigation(
      activeTab: shell.activeTab,
      onCenterActionTap: () {
        unawaited(shell.openFoodCapture());
      },
      onPerformanceTap: () {
        unawaited(shell.openTab(AppMainBottomTab.performance));
      },
      onHomeTap: () {
        unawaited(shell.openTab(AppMainBottomTab.home));
      },
      onMissionsTap: () {
        unawaited(shell.openTab(AppMainBottomTab.missions));
      },
      onSocialTap: () {
        unawaited(shell.openTab(AppMainBottomTab.social));
      },
    );
  }
}
