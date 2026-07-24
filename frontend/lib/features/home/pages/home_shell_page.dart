import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/invite/invite_link_service.dart';
import '../../../core/notifications/meal_reminder_service.dart';
import '../../../core/notifications/in_app_message_store.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_main_bottom_navigation.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../food_analysis/models/food_meal_record.dart';
import '../../food_analysis/pages/food_capture_page.dart';
import '../../missions/pages/missions_page.dart';
import '../../performance/pages/performance_page.dart';
import '../../social/helpers/social_data_invalidator.dart';
import '../../social/pages/social_page.dart';
import '../helpers/home_date_helpers.dart';
import 'home_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({
    super.key,
    this.initialTab = AppMainBottomTab.home,
    this.performancePage,
    this.homePage,
    this.missionsPage,
    this.socialPage,
  });

  /// Opens Social when a friend/group invite deep link is pending.
  factory HomeShellPage.fromLaunch({Key? key}) {
    return HomeShellPage(
      key: key,
      initialTab: InviteLinkService.hasPending
          ? AppMainBottomTab.social
          : AppMainBottomTab.home,
    );
  }

  final AppMainBottomTab initialTab;
  final Widget? performancePage;
  final Widget? homePage;
  final Widget? missionsPage;
  final Widget? socialPage;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage>
    with WidgetsBindingObserver {
  static const int _performanceIndex = 0;
  static const int _homeIndex = 1;
  static const int _missionsIndex = 2;
  static const int _socialIndex = 3;

  /// Avoid refetching every tab switch; keep in-memory data and soft-refresh
  /// only when content is considered stale.
  static const Duration _tabStaleAfter = Duration(seconds: 60);

  late int _currentIndex;
  late DateTime _selectedHomeDate;
  late final PageController _pageController;
  int _performanceRefreshVersion = 0;
  int _missionsRefreshVersion = 0;
  int _socialRefreshVersion = 0;
  int _homeMealSyncVersion = 0;
  FoodMealRecord? _pendingSavedMeal;
  final Set<int> _visitedTabs = <int>{};
  final Map<int, DateTime> _lastTabRefreshAt = <int, DateTime>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = _tabToIndex(widget.initialTab);
    _selectedHomeDate = normalizeHomeDate(DateTime.now());
    _pageController = PageController(initialPage: _currentIndex);
    _visitedTabs.add(_currentIndex);
    _lastTabRefreshAt[_currentIndex] = DateTime.now();
    AnalyticsService.instance.trackAppOpen();
    _trackTabOpened(_currentIndex);
    unawaited(MealReminderService.instance.syncScheduledReminders());
    unawaited(InAppMessageStore.instance.syncDueMealReminders());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(AnalyticsService.instance.leaveForeground(reason: 'dispose'));
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AnalyticsService.instance.trackAppOpen(properties: {'from': 'resume'});
      unawaited(MealReminderService.instance.syncScheduledReminders());
      unawaited(InAppMessageStore.instance.syncDueMealReminders());
      // Soft-refresh the visible tab after returning to the app
      // (inclui virada de dia para média calórica no social).
      _forceSoftRefreshForIndex(_currentIndex);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(
        AnalyticsService.instance.leaveForeground(reason: state.name),
      );
    }
  }

  void _trackTabOpened(int index) {
    switch (index) {
      case _missionsIndex:
        AnalyticsService.instance.trackScreen('missions');
        AnalyticsService.instance.track('missions_tab_opened');
        break;
      case _socialIndex:
        AnalyticsService.instance.trackScreen('social');
        AnalyticsService.instance.track('social_tab_opened');
        break;
      case _performanceIndex:
        AnalyticsService.instance.trackScreen('performance');
        AnalyticsService.instance.track('performance_tab_opened');
        break;
      case _homeIndex:
        AnalyticsService.instance.trackScreen('home');
        AnalyticsService.instance.track('home_tab_opened');
        break;
    }
  }

  AppMainBottomTab get _activeTab {
    if (_currentIndex == _performanceIndex) {
      return AppMainBottomTab.performance;
    }

    if (_currentIndex == _missionsIndex) {
      return AppMainBottomTab.missions;
    }

    if (_currentIndex == _socialIndex) {
      return AppMainBottomTab.social;
    }

    return AppMainBottomTab.home;
  }

  int _tabToIndex(AppMainBottomTab tab) {
    return switch (tab) {
      AppMainBottomTab.performance => _performanceIndex,
      AppMainBottomTab.missions => _missionsIndex,
      AppMainBottomTab.social => _socialIndex,
      _ => _homeIndex,
    };
  }

  void _bumpRefreshForIndex(int index, {bool force = false}) {
    if (index == _homeIndex) {
      return;
    }

    final now = DateTime.now();
    final isFirstVisit = !_visitedTabs.contains(index);
    _visitedTabs.add(index);

    // First visit: the page loads itself in initState — avoid a double fetch
    // that delays things like the social notification FAB.
    if (isFirstVisit && !force) {
      _lastTabRefreshAt[index] = now;
      return;
    }

    final last = _lastTabRefreshAt[index];
    if (!force &&
        last != null &&
        now.difference(last) < _tabStaleAfter) {
      return;
    }

    _lastTabRefreshAt[index] = now;
    switch (index) {
      case _performanceIndex:
        _performanceRefreshVersion++;
        break;
      case _missionsIndex:
        _missionsRefreshVersion++;
        break;
      case _socialIndex:
        _socialRefreshVersion++;
        break;
    }
  }

  void _forceSoftRefreshForIndex(int index) {
    if (!mounted || index == _homeIndex) {
      return;
    }
    setState(() {
      _bumpRefreshForIndex(index, force: true);
    });
  }

  Future<void> _goToTab(AppMainBottomTab tab) async {
    final nextIndex = _tabToIndex(tab);
    if (nextIndex == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = nextIndex;
      _bumpRefreshForIndex(nextIndex);
    });
    _trackTabOpened(nextIndex);

    await _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openFoodCapture() async {
    AnalyticsService.instance.track(
      'meal_capture_started',
      properties: {'entry': 'center_action'},
    );
    final record = await context.pushSlidePage<FoodMealRecord>(
      const FoodCapturePage(),
    );
    if (!mounted) {
      return;
    }

    if (record != null) {
      final recordDate = normalizeHomeDate(record.createdAt ?? DateTime.now());
      setState(() {
        _selectedHomeDate = recordDate;
        _pendingSavedMeal = record;
        _homeMealSyncVersion++;
      });
      await _goToTab(AppMainBottomTab.home);
    }

    // Recalcula ranking de média calórica após possível registro de refeição.
    SocialDataInvalidator.markDirty();
    _forceSoftRefreshForIndex(_socialIndex);
    _forceSoftRefreshForIndex(_performanceIndex);
    _forceSoftRefreshForIndex(_missionsIndex);
  }

  Future<void> _goToHomeDate(DateTime date) async {
    setState(() {
      _selectedHomeDate = normalizeHomeDate(date);
    });

    await _goToTab(AppMainBottomTab.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (!mounted || index == _currentIndex) {
            return;
          }

          setState(() {
            _currentIndex = index;
            _bumpRefreshForIndex(index);
          });
          _trackTabOpened(index);
        },
        children: [
          widget.performancePage ??
              PerformancePage(
                onDateSelected: _goToHomeDate,
                refreshVersion: _performanceRefreshVersion,
              ),
          widget.homePage ??
              HomePage(
                initialSelectedDate: _selectedHomeDate,
                mealSyncVersion: _homeMealSyncVersion,
                pendingSavedMeal: _pendingSavedMeal,
                onSelectedDateChanged: (date) {
                  setState(() {
                    _selectedHomeDate = normalizeHomeDate(date);
                  });
                },
              ),
          widget.missionsPage ??
              MissionsPage(refreshVersion: _missionsRefreshVersion),
          widget.socialPage ?? SocialPage(refreshVersion: _socialRefreshVersion),
        ],
      ),
      bottomNavigationBar: AppMainBottomNavigation(
        activeTab: _activeTab,
        onPerformanceTap: () => _goToTab(AppMainBottomTab.performance),
        onHomeTap: () => _goToTab(AppMainBottomTab.home),
        onMissionsTap: () => _goToTab(AppMainBottomTab.missions),
        onSocialTap: () => _goToTab(AppMainBottomTab.social),
        onCenterActionTap: _openFoodCapture,
      ),
    );
  }
}
