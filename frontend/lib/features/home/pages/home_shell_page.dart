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
import '../../avatar_frames/pages/avatar_frame_store_page.dart';
import '../../food_analysis/models/food_meal_record.dart';
import '../../food_analysis/pages/food_capture_page.dart';
import '../../missions/pages/missions_page.dart';
import '../../notifications/pages/in_app_messages_page.dart';
import '../../performance/pages/performance_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../reminders/pages/meal_reminders_page.dart';
import '../../social/helpers/social_data_invalidator.dart';
import '../../social/pages/social_page.dart';
import '../../support/pages/support_page.dart';
import '../../workouts/pages/workout_page.dart';
import '../controllers/home_steps_weight_controller.dart';
import '../helpers/home_date_helpers.dart';
import '../helpers/home_greeting_helpers.dart';
import '../services/steps_service.dart';
import '../widgets/home_shell_layout.dart';
import '../widgets/home_steps_weight_scope.dart';
import 'home_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({
    super.key,
    this.initialTab = AppMainBottomTab.home,
    this.performancePage,
    this.homePage,
    this.missionsPage,
    this.socialPage,
    this.workoutPage,
    this.stepsService,
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
  final Widget? workoutPage;
  final StepsService? stepsService;

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
  AppMainOverlayDestination get overlayDestination;
  Listenable get navigationListenable;
  Future<void> openTab(AppMainBottomTab tab);
  Future<void> openFoodCapture();
  Future<void> openProfile();
  Future<void> openStore();
  Future<void> openNotifications();
  Future<void> openReminders();
  Future<void> openSupport();
}

class _HomeShellPageState extends State<HomeShellPage>
    with WidgetsBindingObserver
    implements HomeShellController {
  static const int _performanceIndex = 0;
  static const int _homeIndex = 1;
  static const int _socialIndex = 2;

  /// Soft-refresh only on resume / after writes — never on every tab switch.
  /// Switching tabs should reuse in-memory UI (stale-while-revalidate).
  static const Duration _resumeStaleAfter = Duration(minutes: 5);

  late int _currentIndex;
  late AppMainBottomTab _activeTab;
  AppMainOverlayDestination _overlayDestination =
      AppMainOverlayDestination.none;
  late DateTime _selectedHomeDate;
  bool _isMoreMenuOpen = false;
  final _HomeShellNavigationTick _navigationListenable =
      _HomeShellNavigationTick();
  final Set<AppMainBottomTab> _visitedOverflow = <AppMainBottomTab>{};
  late final PageController _pageController;
  int _performanceRefreshVersion = 0;
  int _missionsRefreshVersion = 0;
  int _socialRefreshVersion = 0;
  int _workoutRefreshVersion = 0;
  int _homeMealSyncVersion = 0;
  FoodMealRecord? _pendingSavedMeal;
  final Set<int> _visitedTabs = <int>{};
  final Map<int, DateTime> _lastTabRefreshAt = <int, DateTime>{};
  final GlobalKey _performancePageKey = GlobalKey();
  final GlobalKey _homePageKey = GlobalKey();
  final GlobalKey _missionsPageKey = GlobalKey();
  final GlobalKey _socialPageKey = GlobalKey();
  final GlobalKey _workoutPageKey = GlobalKey();
  final GlobalKey<NavigatorState> _nestedNavigatorKey =
      GlobalKey<NavigatorState>();
  late final _ShellNestedNavigatorObserver _nestedNavObserver;
  late final HomeStepsWeightController _stepsWeightController;

  @override
  void initState() {
    super.initState();
    HomeShellPage._attach(this);
    _stepsWeightController = HomeStepsWeightController(
      stepsService: widget.stepsService,
    );
    unawaited(_stepsWeightController.ensureLoaded());
    WidgetsBinding.instance.addObserver(this);
    _nestedNavObserver = _ShellNestedNavigatorObserver(
      onChange: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    _activeTab = widget.initialTab;
    _currentIndex = _isSwipeTab(widget.initialTab)
        ? _tabToIndex(widget.initialTab)
        : _homeIndex;
    if (!_isSwipeTab(widget.initialTab)) {
      _visitedOverflow.add(widget.initialTab);
    }
    _selectedHomeDate = normalizeHomeDate(DateTime.now());
    _pageController = PageController(initialPage: _currentIndex);
    _visitedTabs.add(_currentIndex);
    _lastTabRefreshAt[_currentIndex] = DateTime.now();
    AnalyticsService.instance.trackAppOpen();
    _trackTabOpened(_activeTab);
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
    _stepsWeightController.dispose();
    _navigationListenable.dispose();
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
      if (_isSwipeTab(_activeTab)) {
        _forceSoftRefreshForIndex(_currentIndex);
      } else {
        _forceSoftRefreshForTab(_activeTab);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(AnalyticsService.instance.leaveForeground(reason: state.name));
    }
  }

  void _trackTabOpened(AppMainBottomTab tab) {
    switch (tab) {
      case AppMainBottomTab.missions:
        AnalyticsService.instance.trackScreen('missions');
        AnalyticsService.instance.track('missions_tab_opened');
        break;
      case AppMainBottomTab.social:
        AnalyticsService.instance.trackScreen('social');
        AnalyticsService.instance.track('social_tab_opened');
        break;
      case AppMainBottomTab.performance:
        AnalyticsService.instance.trackScreen('performance');
        AnalyticsService.instance.track('performance_tab_opened');
        break;
      case AppMainBottomTab.workout:
        AnalyticsService.instance.trackScreen('workout');
        AnalyticsService.instance.track('workout_tab_opened');
        break;
      case AppMainBottomTab.home:
        AnalyticsService.instance.trackScreen('home');
        AnalyticsService.instance.track('home_tab_opened');
        break;
    }
  }

  @override
  AppMainBottomTab get activeTab => _activeTab;

  @override
  AppMainOverlayDestination get overlayDestination => _overlayDestination;

  @override
  Listenable get navigationListenable => _navigationListenable;

  bool get _hasOverlayDestination {
    return _overlayDestination != AppMainOverlayDestination.none;
  }

  void _notifyNavigation() {
    _navigationListenable.tick();
  }

  void _clearOverlayDestination() {
    if (_overlayDestination == AppMainOverlayDestination.none) {
      return;
    }
    _overlayDestination = AppMainOverlayDestination.none;
  }

  bool _isSwipeTab(AppMainBottomTab tab) {
    return tab == AppMainBottomTab.social ||
        tab == AppMainBottomTab.home ||
        tab == AppMainBottomTab.performance;
  }

  bool get _isOverflowTab => !_isSwipeTab(_activeTab);

  AppMainBottomTab _indexToTab(int index) {
    return switch (index) {
      _socialIndex => AppMainBottomTab.social,
      _performanceIndex => AppMainBottomTab.performance,
      _ => AppMainBottomTab.home,
    };
  }

  int _tabToIndex(AppMainBottomTab tab) {
    return switch (tab) {
      AppMainBottomTab.social => _socialIndex,
      AppMainBottomTab.performance => _performanceIndex,
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
      case _socialIndex:
        _socialRefreshVersion++;
        break;
    }
  }

  void _forceSoftRefreshForTab(AppMainBottomTab tab) {
    if (!mounted || tab == AppMainBottomTab.home) {
      return;
    }
    if (_isSwipeTab(tab)) {
      _forceSoftRefreshForIndex(_tabToIndex(tab));
      return;
    }
    setState(() {
      if (tab == AppMainBottomTab.missions) {
        _missionsRefreshVersion++;
      } else if (tab == AppMainBottomTab.workout) {
        _workoutRefreshVersion++;
      }
    });
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
    final hadOverlay = _hasOverlayDestination;
    _popNestedOverlays();
    if (tab == _activeTab && !_isMoreMenuOpen && !hadOverlay) {
      return;
    }

    if (!_isSwipeTab(tab)) {
      setState(() {
        _clearOverlayDestination();
        _isMoreMenuOpen = false;
        _activeTab = tab;
        _visitedOverflow.add(tab);
      });
      _notifyNavigation();
      _trackTabOpened(tab);
      return;
    }

    final nextIndex = _tabToIndex(tab);
    final isAdjacent =
        !_isOverflowTab && (nextIndex - _currentIndex).abs() == 1;

    setState(() {
      _clearOverlayDestination();
      _isMoreMenuOpen = false;
      _activeTab = tab;
      _currentIndex = nextIndex;
      _visitedTabs.add(nextIndex);
      _lastTabRefreshAt.putIfAbsent(nextIndex, DateTime.now);
    });
    _notifyNavigation();
    _trackTabOpened(tab);

    if (_pageController.hasClients && _pageController.page != nextIndex) {
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
    return;
  }

  @override
  Future<void> openFoodCapture() => _openFoodCapture();

  @override
  Future<void> openProfile() => _openProfile();

  @override
  Future<void> openStore() => _openStore();

  @override
  Future<void> openNotifications() => _openNotifications();

  @override
  Future<void> openReminders() => _openReminders();

  @override
  Future<void> openSupport() => _openSupport();

  Future<T?> _pushOverlay<T>(
    AppMainOverlayDestination destination,
    Future<T?> Function(BuildContext nestedContext) push,
  ) async {
    if (_isMoreMenuOpen) {
      setState(() => _isMoreMenuOpen = false);
    }

    final nestedContext = _nestedNavigatorKey.currentContext;
    if (nestedContext == null) {
      return null;
    }

    final previousDestination = _overlayDestination;
    setState(() {
      _overlayDestination = destination;
    });
    _notifyNavigation();

    try {
      return await push(nestedContext);
    } finally {
      if (mounted && _overlayDestination == destination) {
        setState(() {
          _overlayDestination = previousDestination;
        });
        _notifyNavigation();
      }
    }
  }

  Future<void> _openProfile() async {
    await _pushOverlay<bool>(
      AppMainOverlayDestination.profile,
      (nestedContext) {
        return nestedContext.pushSlidePage<bool>(
          ProfilePage(initialProfile: AuthService.globalUser),
        );
      },
    );
  }

  Future<void> _openNotifications() async {
    await _pushOverlay<void>(
      AppMainOverlayDestination.notifications,
      (nestedContext) {
        return nestedContext.pushSlidePage(
          InAppMessagesPage(store: InAppMessageStore.instance),
        );
      },
    );
  }

  Future<void> _openReminders() async {
    await _pushOverlay<void>(
      AppMainOverlayDestination.reminders,
      (nestedContext) {
        return nestedContext.pushSlidePage(const MealRemindersPage());
      },
    );
  }

  Future<void> _openSupport() async {
    await _pushOverlay<void>(
      AppMainOverlayDestination.support,
      (nestedContext) {
        return nestedContext.pushSlidePage(const SupportPage());
      },
    );
  }

  Future<void> _openStore() async {
    final profile = AuthService.globalUser ?? const <String, dynamic>{};
    final goldRaw = profile['gold'];
    final gold = goldRaw is int
        ? goldRaw
        : goldRaw is num
        ? goldRaw.toInt()
        : int.tryParse('$goldRaw') ?? 0;

    final updated = await _pushOverlay<Object>(
      AppMainOverlayDestination.store,
      (nestedContext) {
        return nestedContext.pushSlidePage<Object>(
          AvatarFrameStorePage(
            initialGoldBalance: gold,
            profile: Map<String, dynamic>.from(profile),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }
    if (updated == 'go_to_missions') {
      await _goToTab(AppMainBottomTab.missions);
    }
  }

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
    _forceSoftRefreshForTab(AppMainBottomTab.missions);
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
      _socialIndex =>
        widget.socialPage ??
            SocialPage(
              key: _socialPageKey,
              refreshVersion: _socialRefreshVersion,
            ),
      _performanceIndex =>
        widget.performancePage ??
            PerformancePage(
              key: _performancePageKey,
              onDateSelected: _goToHomeDate,
              refreshVersion: _performanceRefreshVersion,
            ),
      _ =>
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
    };
  }

  Widget _buildMissionsPage() {
    return widget.missionsPage ??
        MissionsPage(
          key: _missionsPageKey,
          refreshVersion: _missionsRefreshVersion,
        );
  }

  Widget _buildWorkoutPage() {
    return widget.workoutPage ??
        WorkoutPage(
          key: _workoutPageKey,
          refreshVersion: _workoutRefreshVersion,
        );
  }

  Widget _buildShellBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: _isOverflowTab, child: _buildTabsPageView()),
        if (_visitedOverflow.contains(AppMainBottomTab.missions))
          Offstage(
            offstage: _activeTab != AppMainBottomTab.missions,
            child: _buildMissionsPage(),
          ),
        if (_visitedOverflow.contains(AppMainBottomTab.workout))
          Offstage(
            offstage: _activeTab != AppMainBottomTab.workout,
            child: _buildWorkoutPage(),
          ),
      ],
    );
  }

  Widget _buildTabsPageView() {
    return PreferVerticalPageView(
      controller: _pageController,
      onPageChanged: (index) {
        if (!mounted || index == _currentIndex) {
          return;
        }

        setState(() {
          _clearOverlayDestination();
          _isMoreMenuOpen = false;
          _currentIndex = index;
          _activeTab = _indexToTab(index);
          _visitedTabs.add(index);
          _lastTabRefreshAt.putIfAbsent(index, DateTime.now);
        });
        _notifyNavigation();
        _trackTabOpened(_indexToTab(index));
      },
      children: List<Widget>.generate(3, _buildTabPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nestedCanPop = _nestedNavigatorKey.currentState?.canPop() ?? false;
    final navOverlap =
        homeShellBottomNavBodyHeight +
        homeShellBottomNavFloatingGap +
        MediaQuery.viewPaddingOf(context).bottom;

    return HomeStepsWeightScope(
      controller: _stepsWeightController,
      child: HomeShellLayout(
        navOverlap: navOverlap,
        child: PopScope(
          canPop: !nestedCanPop,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _nestedNavigatorKey.currentState?.maybePop();
          },
          child: Builder(
            builder: (context) {
              final mediaQuery = MediaQuery.of(context);
              final paddedMediaQuery = mediaQuery.copyWith(
                padding: mediaQuery.padding.copyWith(bottom: navOverlap),
              );

              return Scaffold(
                backgroundColor: AppColors.pageBackground,
                resizeToAvoidBottomInset: false,
                body: Stack(
                  children: [
                    MediaQuery(
                      data: paddedMediaQuery,
                      child: Navigator(
                        key: _nestedNavigatorKey,
                        observers: <NavigatorObserver>[_nestedNavObserver],
                        onGenerateRoute: (settings) {
                          return PageRouteBuilder<void>(
                            settings: settings,
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                                  return _buildShellBody();
                                },
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AppMainBottomNavigation(
                        activeTab: _activeTab,
                        overlayDestination: _overlayDestination,
                        isMoreMenuOpen: _isMoreMenuOpen,
                        onMoreTap: () {
                          setState(() {
                            _isMoreMenuOpen = !_isMoreMenuOpen;
                          });
                        },
                        onPerformanceTap: () =>
                            _goToTab(AppMainBottomTab.performance),
                        onWorkoutTap: () => _goToTab(AppMainBottomTab.workout),
                        onNotificationsTap: _openNotifications,
                        onRemindersTap: _openReminders,
                        onSupportTap: _openSupport,
                        onStoreTap: _openStore,
                        onProfileTap: _openProfile,
                        onHomeTap: () => _goToTab(AppMainBottomTab.home),
                        onMissionsTap: () =>
                            _goToTab(AppMainBottomTab.missions),
                        onSocialTap: () => _goToTab(AppMainBottomTab.social),
                        onCenterActionTap: _openFoodCapture,
                      ),
                    ),
                  ],
                ),
              );
            },
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

class _HomeShellNavigationTick extends ChangeNotifier {
  void tick() => notifyListeners();
}
