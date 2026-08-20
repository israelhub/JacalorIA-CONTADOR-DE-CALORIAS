import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

const homeShellFabNavGap = AppSpacing.lg;

const homeShellBottomNavBodyHeight = 56.0 + AppSpacing.xs;

class HomeShellLayout extends InheritedWidget {
  const HomeShellLayout({
    super.key,
    required this.navOverlap,
    required super.child,
  });

  final double navOverlap;

  static HomeShellLayout? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeShellLayout>();
  }

  @override
  bool updateShouldNotify(HomeShellLayout oldWidget) {
    return navOverlap != oldWidget.navOverlap;
  }
}

double homeShellNavOverlap(BuildContext context) {
  final fromShell = HomeShellLayout.maybeOf(context)?.navOverlap;
  if (fromShell != null) {
    return fromShell;
  }

  final mediaQuery = MediaQuery.of(context);
  if (mediaQuery.padding.bottom > mediaQuery.viewPadding.bottom) {
    return mediaQuery.padding.bottom;
  }
  return homeShellBottomNavBodyHeight + mediaQuery.viewPadding.bottom;
}

EdgeInsets homeShellNestedFillPadding(
  BuildContext context, {
  double horizontal = AppSpacing.lg,
  double top = AppSpacing.lg,
}) {
  return EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    homeShellNavOverlap(context),
  );
}

double homeShellScrollBottomInset(
  BuildContext context, {
  double extra = AppSpacing.xxxl,
}) {
  return homeShellNavOverlap(context) + extra;
}

double homeShellFabBottomInset(BuildContext context) {
  // Nested Scaffold ignora o padding da nav do shell; endFloat ja soma 16px.
  final navSurfaceOverlap = homeShellNavOverlap(context) - AppSpacing.xs;
  final inset =
      navSurfaceOverlap - kFloatingActionButtonMargin + homeShellFabNavGap;
  return inset < 0 ? 0 : inset;
}

double homeShellToastBottomInset(BuildContext context) {
  final shell = context.getInheritedWidgetOfExactType<HomeShellLayout>();
  final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  final base = shell?.navOverlap ?? safeBottom;
  final above = base > keyboard ? base : keyboard;
  return above + AppSpacing.lg;
}
