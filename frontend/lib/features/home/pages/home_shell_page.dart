import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/invite/invite_link_service.dart';
import '../../../core/notifications/meal_reminder_service.dart';
import '../../../core/notifications/meal_reminder_home_widget.dart';
import '../../../core/notifications/in_app_message_store.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_main_bottom_navigation.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/prefer_vertical_page_view.dart';
import '../../auth/service/auth_service.dart';
import '../../food_analysis/models/food_meal_record.dart';
import '../../food_analysis/pages/food_capture_page.dart';
import '../../missions/pages/missions_page.dart';
import '../../performance/pages/performance_page.dart';
import '../../social/helpers/social_data_invalidator.dart';
import '../../social/pages/social_page.dart';
import '../helpers/home_date_helpers.dart';
import '../helpers/home_greeting_helpers.dart';
import '../widgets/home_shell_layout.dart';
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

  static HomeShellController? _controller;

  static HomeShellController? get maybeController => _controller;

  static HomeShellController? controllerOf(BuildContext context) {
    return context.findAncestorStateOfType<_HomeShellPageState>() ??
        _controller;
  }

  static void _attach(HomeShellController controller) {
    _controller = controller;
  }

  static void _detach(HomeShellController controller) {
    if (identical(_controller, controller)) {
      _controller = null;
    }
  }

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

abstract class HomeShellController {
  AppMainBottomTab get activeTab;
  Future<void> openTab(AppMainBottomTab tab);
  Future<void> openFoodCapture();
}

class _HomeShellPageState extends State<HomeShellPage>
    with WidgetsBindingObserver
    implements HomeShellController {
  static const int _performanceIndex = 0;
  static const int _homeIndex = 1;
  static const int _missionsIndex = 2;
  static const int _socialIndex = 3;

  /// Soft-refresh only on resume / after writes — never on every tab switch.
  /// Switching tabs should reuse in-memory UI (stale-while-revalidate).
  static const Duration _resumeStaleAfter = Duration(minutes: 5);

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
  final GlobalKey _performancePageKey = GlobalKey();
  final GlobalKey _homePageKey = GlobalKey();
  final GlobalKey _missionsPageKey = GlobalKey();
  final GlobalKey _socialPageKey = GlobalKey();
  final GlobalKey<NavigatorState> _nestedNavigatorKey =
      GlobalKey<NavigatorState>();
  late final _ShellNestedNavigatorObserver _nestedNavObserver;

  @override
  void initState() {
    super.initState();
    HomeShellPage._attach(this);
    WidgetsBinding.instance.addObserver(this);
    _nestedNavObserver = _ShellNestedNavigatorObserver(
      onChange: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    _currentIndex = _tabToIndex(widget.initialTab);
    _selectedHomeDate = normalizeHomeDate(DateTime.now());
    _pageController = PageController(initialPage: _currentIndex);
    _visitedTabs.add(_currentIndex);
    _lastTabRefreshAt[_currentIndex] = DateTime.now();
    AnalyticsService.instance.trackAppOpen();
    _trackTabOpened(_currentIndex);
    unawaited(MealReminderService.instance.syncScheduledReminders());
    unawaited(
      MealReminderHomeWidget.sync(
        streakDays: readHomeProfileInt(AuthService.globalUser, const [
          'streakDays',
          'streak_days',
        ]),
      ),
    );
    unawaited(InAppMessageStore.instance.syncDueMealReminders());
    unawaited(InAppMessageStore.instance.syncRemoteCatalog());
    InviteLinkService.revision.addListener(_onPendingInviteRevision);
  }

  void _onPendingInviteRevision() {
    if (!mounted || !InviteLinkService.hasPending) {
      return;
    }
    unawaited(_goToTab(AppMainBottomTab.social));
  }

  @override
  void dispose() {
    HomeShellPage._detach(this);
    InviteLinkService.revision.removeListener(_onPendingInviteRevision);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(AnalyticsService.instance.leaveForeground(reason: 'dispose'));
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AnalyticsService.instance.trackAppOpen(properties: {'from': 'resume'});
      unawaited(AuthService.refreshSession());
      unawaited(MealReminderService.instance.syncScheduledReminders());
      unawaited(
        MealReminderHomeWidget.sync(
          streakDays: readHomeProfileInt(AuthService.globalUser, const [
            'streakDays',
            'streak_days',
          ]),
        ),
      );
      unawaited(InAppMessageStore.instance.syncDueMealReminders());
      unawaited(InAppMessageStore.instance.syncRemoteCatalog());
      // Soft-refresh the visible tab after returning to the app
      // (inclui virada de dia para média calórica no social).
      _forceSoftRefreshForIndex(_currentIndex);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(AnalyticsService.instance.leaveForeground(reason: state.name));
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

  @override
  AppMainBottomTab get activeTab => _activeTab;

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

    // First visit: page loads itself in initState — avoid a double fetch.
    if (isFirstVisit && !force) {
      _lastTabRefreshAt[index] = now;
      return;
    }

    // Tab switches never refetch. Only resume / meal writes force soft refresh.
    if (!force) {
      return;
    }

    final last = _lastTabRefreshAt[index];
    if (last != null && now.difference(last) < _resumeStaleAfter) {
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

  @override
  Future<void> openTab(AppMainBottomTab tab) => _goToTab(tab);

  void _popNestedOverlays() {
    final nested = _nestedNavigatorKey.currentState;
    if (nested == null || !nested.canPop()) {
      return;
    }
    nested.popUntil((route) => route.isFirst);
  }

  Future<void> _goToTab(AppMainBottomTab tab) async {
    _popNestedOverlays();
    final nextIndex = _tabToIndex(tab);
    if (nextIndex == _currentIndex) {
      return;
    }

    final isAdjacent = (nextIndex - _currentIndex).abs() == 1;

    setState(() {
      _currentIndex = nextIndex;
      // Mark visited so the page mounts once; do not network-refresh.
      _visitedTabs.add(nextIndex);
      _lastTabRefreshAt.putIfAbsent(nextIndex, DateTime.now);
    });
    _trackTabOpened(nextIndex);

    // Saltos nao adjacentes renderizariam as abas intermediarias durante a
    // animacao; pular direto evita esse custo.
    if (!isAdjacent) {
      _pageController.jumpToPage(nextIndex);
      return;
    }

    await _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Future<void> openFoodCapture() => _openFoodCapture();

  Future<void> _openFoodCapture() async {
    AnalyticsService.instance.track(
      'meal_capture_started',
      properties: {'entry': 'center_action'},
    );
    final record = await context.pushSlidePage<FoodMealRecord>(
      FoodCapturePage(
        recordedAt: resolveMealRecordedAt(selectedDate: _selectedHomeDate),
      ),
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

  Widget _buildTabPage(int index) {
    if (!_visitedTabs.contains(index)) {
      return const ColoredBox(color: AppColors.surface);
    }

    return switch (index) {
      _performanceIndex =>
        widget.performancePage ??
            PerformancePage(
              key: _performancePageKey,
              onDateSelected: _goToHomeDate,
              refreshVersion: _performanceRefreshVersion,
            ),
      _homeIndex =>
        widget.homePage ??
            HomePage(
              key: _homePageKey,
              initialSelectedDate: _selectedHomeDate,
              mealSyncVersion: _homeMealSyncVersion,
              pendingSavedMeal: _pendingSavedMeal,
              onSelectedDateChanged: (date) {
                setState(() {
                  _selectedHomeDate = normalizeHomeDate(date);
                });
              },
            ),
      _missionsIndex =>
        widget.missionsPage ??
            MissionsPage(
              key: _missionsPageKey,
              refreshVersion: _missionsRefreshVersion,
            ),
      _ =>
        widget.socialPage ??
            SocialPage(
              key: _socialPageKey,
              refreshVersion: _socialRefreshVersion,
            ),
    };
  }

  Widget _buildTabsPageView() {
    return PreferVerticalPageView(
      controller: _pageController,
      onPageChanged: (index) {
        if (!mounted || index == _currentIndex) {
          return;
        }

        setState(() {
          _currentIndex = index;
          _visitedTabs.add(index);
          _lastTabRefreshAt.putIfAbsent(index, DateTime.now);
        });
        _trackTabOpened(index);
      },
      children: List<Widget>.generate(4, _buildTabPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nestedCanPop = _nestedNavigatorKey.currentState?.canPop() ?? false;
    final navOverlap =
        homeShellBottomNavBodyHeight + MediaQuery.viewPaddingOf(context).bottom;

    return HomeShellLayout(
      navOverlap: navOverlap,
      child: PopScope(
        canPop: !nestedCanPop,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            return;
          }
          _nestedNavigatorKey.currentState?.maybePop();
        },
        child: Scaffold(
          backgroundColor: AppColors.surface,
          extendBody: true,
          body: Navigator(
            key: _nestedNavigatorKey,
            observers: <NavigatorObserver>[_nestedNavObserver],
            onGenerateRoute: (settings) {
              return PageRouteBuilder<void>(
                settings: settings,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return _buildTabsPageView();
                },
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              );
            },
          ),
          bottomNavigationBar: AppMainBottomNavigation(
            activeTab: _activeTab,
            onPerformanceTap: () => _goToTab(AppMainBottomTab.performance),
            onHomeTap: () => _goToTab(AppMainBottomTab.home),
            onMissionsTap: () => _goToTab(AppMainBottomTab.missions),
            onSocialTap: () => _goToTab(AppMainBottomTab.social),
            onCenterActionTap: _openFoodCapture,
          ),
        ),
      ),
    );
  }
}

class _ShellNestedNavigatorObserver extends NavigatorObserver {
  _ShellNestedNavigatorObserver({required this.onChange});

  final VoidCallback onChange;

  void _notify() {
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _notify();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _notify();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _notify();
}
