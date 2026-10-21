import 'package:flutter/material.dart';

class HomeShellProductTourTargets {
  HomeShellProductTourTargets._();

  static final GlobalKey dailyGoalCard = GlobalKey(
    debugLabel: 'product-tour-daily-goal',
  );

  static final GlobalKey mealsSection = GlobalKey(
    debugLabel: 'product-tour-meals-section',
  );

  static final GlobalKey dailyMissionsSection = GlobalKey(
    debugLabel: 'product-tour-daily-missions',
  );

  static final GlobalKey openStoreButton = GlobalKey(
    debugLabel: 'product-tour-open-store',
  );

  static final GlobalKey socialTabs = GlobalKey(
    debugLabel: 'product-tour-social-tabs',
  );
}
