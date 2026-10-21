import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/invite/invite_link_service.dart';
import '../../../core/notifications/meal_reminder_service.dart';
import '../../../core/notifications/meal_reminder_home_widget.dart';
import '../../../core/notifications/in_app_message_store.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_coach_mark_overlay.dart';
import '../../../shared/widgets/app_main_bottom_navigation.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/prefer_vertical_page_view.dart';
import '../../auth/service/auth_service.dart';
import '../../avatar_frames/pages/avatar_frame_store_page.dart';
import '../../food_analysis/models/food_meal_record.dart';
import '../../food_analysis/pages/food_capture_page.dart';
import '../../missions/pages/missions_page.dart';
import '../../notifications/pages/in_app_messages_page.dart';
import '../../performance/pages/performance_page.dart';
import '../../profile/helpers/user_manual_content.dart';
import '../../profile/helpers/user_manual_guided_tour_steps.dart';
import '../../profile/helpers/user_manual_guided_tour_targets.dart';
import '../../profile/pages/profile_page.dart';
import '../../reminders/pages/meal_reminders_page.dart';
import '../../social/helpers/social_data_invalidator.dart';
import '../../social/pages/social_page.dart';
import '../../support/pages/support_page.dart';
import '../../workouts/pages/workout_page.dart';
import '../controllers/home_steps_weight_controller.dart';
import '../helpers/home_date_helpers.dart';
import '../helpers/home_greeting_helpers.dart';
import '../helpers/home_shell_product_tour_prefs.dart';
import '../helpers/home_shell_product_tour_steps.dart';
import '../helpers/home_shell_product_tour_targets.dart';
import '../services/steps_service.dart';
import '../widgets/home_product_tour_congrats_dialog.dart';
import '../widgets/home_shell_layout.dart';
import '../widgets/home_steps_weight_scope.dart';
import 'home_page.dart';

enum HomeShellProductTourMode { auto, force, off }

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
    this.productTourMode = HomeShellProductTourMode.auto,
    this.productTourPrefs,
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
  final HomeShellProductTourMode productTourMode;
  final HomeShellProductTourPrefs? productTourPrefs;

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
  Future<void> restartProductTour();
  Future<void> startManualGuidedTour(UserManualGuidedTourId tourId);
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
  final GlobalKey _tourContentKey = GlobalKey();
  final ScrollController _homeScrollController = ScrollController();
  final GlobalKey _performanceTabKey = GlobalKey(
    debugLabel: 'product-tour-performance-tab',
  );
  final GlobalKey _homeTabKey = GlobalKey(debugLabel: 'product-tour-home-tab');
  final GlobalKey _socialTabKey = GlobalKey(
    debugLabel: 'product-tour-social-tab',
  );
  final GlobalKey _moreTabKey = GlobalKey(debugLabel: 'product-tour-more-tab');
  final GlobalKey _missionsDestinationKey = GlobalKey(
    debugLabel: 'product-tour-missions-destination',
  );
  final GlobalKey _morePanelKey = GlobalKey(
    debugLabel: 'product-tour-more-panel',
  );
  final GlobalKey _moreBundleKey = GlobalKey(
    debugLabel: 'product-tour-more-bundle',
  );
  final GlobalKey _centerActionKey = GlobalKey(
    debugLabel: 'product-tour-center-action',
  );
  final GlobalKey<NavigatorState> _nestedNavigatorKey =
      GlobalKey<NavigatorState>();
  late final _ShellNestedNavigatorObserver _nestedNavObserver;
  late final HomeStepsWeightController _stepsWeightController;
  late final HomeShellProductTourPrefs _productTourPrefs;
  bool _productTourVisible = false;
  bool _productTourChromeVisible = false;
  bool _productTourIsReplay = false;
  UserManualGuidedTourId? _manualGuidedTourId;
  List<ManualGuidedTourStep> _manualGuidedSteps = const <ManualGuidedTourStep>[];
  int _productTourStepIndex = 0;
  List<AppCoachMarkHighlight> _productTourHighlights =
      const <AppCoachMarkHighlight>[];
  bool _productTourBusy = false;
  int _productTourPrepareToken = 0;

  @override
  void initState() {
    super.initState();
    HomeShellPage._attach(this);
    _productTourPrefs =
        widget.productTourPrefs ?? HomeShellProductTourPrefs();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeStartProductTour());
    });
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
    _homeScrollController.dispose();
    _stepsWeightController.dispose();
    _navigationListenable.dispose();
    super.dispose();
  }

  void _scrollHomeToTop() {
    if (!_homeScrollController.hasClients) {
      return;
    }
    _homeScrollController.jumpTo(0);
  }

  void _scrollHomeToTopSoon() {
    void attempt() {
      if (!mounted) {
        return;
      }
      _scrollHomeToTop();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
    Future<void>.delayed(const Duration(milliseconds: 260), attempt);
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

  @override
  Future<void> restartProductTour() async {
    if (!mounted ||
        widget.productTourMode == HomeShellProductTourMode.off ||
        _productTourBusy) {
      return;
    }

    _productTourPrepareToken += 1;
    if (_productTourVisible) {
      setState(() {
        _productTourVisible = false;
        _productTourChromeVisible = false;
        _productTourHighlights = const <AppCoachMarkHighlight>[];
        _productTourBusy = false;
        _isMoreMenuOpen = false;
        _manualGuidedTourId = null;
        _manualGuidedSteps = const <ManualGuidedTourStep>[];
      });
    }

    await _productTourPrefs.clearProgress();
    if (!mounted) {
      return;
    }

    _productTourIsReplay = true;
    _manualGuidedTourId = null;
    _manualGuidedSteps = const <ManualGuidedTourStep>[];
    await _goToTab(AppMainBottomTab.home);
    if (!mounted) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || _productTourVisible) {
      return;
    }

    AnalyticsService.instance.track(
      'product_tour_started',
      properties: {'resume_index': 0, 'replay': true},
    );
    setState(() {
      _productTourVisible = true;
      _productTourChromeVisible = false;
      _productTourStepIndex = 0;
      _productTourHighlights = const <AppCoachMarkHighlight>[];
    });
    await _prepareProductTourStep(0);
  }

  @override
  Future<void> startManualGuidedTour(UserManualGuidedTourId tourId) async {
    if (!mounted || _productTourBusy) {
      return;
    }
    if (tourId == UserManualGuidedTourId.initial) {
      await restartProductTour();
      return;
    }

    final steps = manualGuidedTourStepsById[tourId];
    if (steps == null || steps.isEmpty) {
      return;
    }

    _productTourPrepareToken += 1;
    if (_productTourVisible) {
      setState(() {
        _productTourVisible = false;
        _productTourChromeVisible = false;
        _productTourHighlights = const <AppCoachMarkHighlight>[];
        _productTourBusy = false;
        _isMoreMenuOpen = false;
      });
    }

    _productTourIsReplay = false;
    setState(() {
      _manualGuidedTourId = tourId;
      _manualGuidedSteps = steps;
    });

    await _goToTab(AppMainBottomTab.home);
    if (!mounted) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) {
      return;
    }

    AnalyticsService.instance.track(
      'manual_guided_tour_started',
      properties: {'tour': tourId.name},
    );
    setState(() {
      _productTourVisible = true;
      _productTourChromeVisible = false;
      _productTourStepIndex = 0;
      _productTourHighlights = const <AppCoachMarkHighlight>[];
    });
    await _prepareManualGuidedTourStep(0);
  }

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
              scrollController: _homeScrollController,
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
      allowHorizontalSwipe: !_productTourVisible,
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

  Future<bool> _resolveShouldShowProductTour() async {
    try {
      final profile = await AuthService().fetchProfile(forceRefresh: true);
      return HomeShellProductTourPrefs.shouldShow(profile);
    } catch (_) {
      if (HomeShellProductTourPrefs.shouldShow()) {
        return true;
      }
      // Token sem perfil em cache: tenta de novo depois do boot da sessao.
      if (AuthService.globalToken != null && AuthService.globalUser == null) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        try {
          final profile = await AuthService().fetchProfile(forceRefresh: true);
          return HomeShellProductTourPrefs.shouldShow(profile);
        } catch (_) {
          return false;
        }
      }
      return false;
    }
  }

  Future<void> _maybeStartProductTour() async {
    if (!mounted ||
        widget.productTourMode == HomeShellProductTourMode.off ||
        _productTourVisible) {
      return;
    }

    final shouldStart = switch (widget.productTourMode) {
      HomeShellProductTourMode.force => true,
      HomeShellProductTourMode.off => false,
      HomeShellProductTourMode.auto => await _resolveShouldShowProductTour(),
    };
    if (!mounted || !shouldStart || _productTourVisible) {
      return;
    }

    final resumeIndex = widget.productTourMode == HomeShellProductTourMode.force
        ? 0
        : await _productTourPrefs.resolveResumeIndex(homeShellProductTourSteps);
    if (!mounted || _productTourVisible) {
      return;
    }

    AnalyticsService.instance.track(
      'product_tour_started',
      properties: {'resume_index': resumeIndex},
    );
    _productTourIsReplay = false;
    _manualGuidedTourId = null;
    _manualGuidedSteps = const <ManualGuidedTourStep>[];
    setState(() {
      _productTourVisible = true;
      _productTourChromeVisible = false;
      _productTourStepIndex = resumeIndex;
      _productTourHighlights = const <AppCoachMarkHighlight>[];
    });
    await _prepareProductTourStep(resumeIndex);
  }

  HomeShellProductTourStep get _currentProductTourStep {
    return homeShellProductTourSteps[_productTourStepIndex];
  }

  List<({GlobalKey key, double inflate, double radius})>
  _targetsForProductTourStep(HomeShellProductTourStep step) {
    return switch (step.id) {
      HomeShellProductTourStepId.home => [
        (key: _homeTabKey, inflate: 6, radius: AppRadius.md),
      ],
      HomeShellProductTourStepId.dailyGoal => [
        (
          key: HomeShellProductTourTargets.dailyGoalCard,
          inflate: 0,
          radius: AppRadius.lg,
        ),
      ],
      HomeShellProductTourStepId.meals => [
        (
          key: HomeShellProductTourTargets.mealsSection,
          inflate: 0,
          radius: AppRadius.lg,
        ),
        (key: _centerActionKey, inflate: 10, radius: AppRadius.md),
      ],
      HomeShellProductTourStepId.social => [
        (key: _socialTabKey, inflate: 6, radius: AppRadius.md),
      ],
      HomeShellProductTourStepId.socialTabs => [
        (
          key: HomeShellProductTourTargets.socialTabs,
          inflate: 0,
          radius: AppRadius.lg,
        ),
      ],
      HomeShellProductTourStepId.performance => [
        (key: _performanceTabKey, inflate: 6, radius: AppRadius.md),
      ],
      HomeShellProductTourStepId.more => [
        (key: _morePanelKey, inflate: 2, radius: AppRadius.xl),
        (key: _moreTabKey, inflate: 6, radius: AppRadius.md),
      ],
      HomeShellProductTourStepId.missions => [
        (
          key: HomeShellProductTourTargets.dailyMissionsSection,
          inflate: 0,
          radius: AppRadius.lg,
        ),
      ],
      HomeShellProductTourStepId.store => [
        (
          key: HomeShellProductTourTargets.openStoreButton,
          inflate: 8,
          radius: AppRadius.md,
        ),
      ],
    };
  }

  Rect? _rectForKey(GlobalKey key, {double inflate = 0}) {
    final context = key.currentContext;
    if (context == null) {
      return null;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) {
      return null;
    }
    final offset = box.localToGlobal(Offset.zero);
    final rect = offset & box.size;
    return inflate == 0 ? rect : rect.inflate(inflate);
  }

  Future<Rect?> _waitForTargetRect(
    GlobalKey key, {
    double inflate = 0,
    int attempts = 6,
  }) async {
    for (var i = 0; i < attempts; i++) {
      final rect = _rectForKey(key, inflate: inflate);
      if (rect != null && rect.width > 8 && rect.height > 8) {
        return rect;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) {
        return null;
      }
    }
    return _rectForKey(key, inflate: inflate);
  }

  Future<void> _prepareProductTourStep(int index) async {
    if (!mounted || index < 0 || index >= homeShellProductTourSteps.length) {
      return;
    }

    final prepareToken = ++_productTourPrepareToken;
    _productTourBusy = true;
    final step = homeShellProductTourSteps[index];

    // Oculta card/highlight, navega/carrega, so revela quando o alvo estiver pronto.
    setState(() {
      _productTourChromeVisible = false;
      _productTourHighlights = const <AppCoachMarkHighlight>[];
      if (!step.openMoreMenu && _isMoreMenuOpen) {
        _isMoreMenuOpen = false;
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted || prepareToken != _productTourPrepareToken) {
      return;
    }

    if (step.openMoreMenu) {
      if (step.tab != null) {
        await _goToTab(step.tab!);
      }
      if (mounted) {
        setState(() {
          _isMoreMenuOpen = true;
        });
      }
      await Future<void>.delayed(const Duration(milliseconds: 650));
    } else if (step.tab != null) {
      await _goToTab(step.tab!);
      await Future<void>.delayed(
        Duration(milliseconds: step.waitForTarget ? 280 : 180),
      );
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    if (!mounted || prepareToken != _productTourPrepareToken) {
      return;
    }

    final targets = _targetsForProductTourStep(step);
    final highlights = <AppCoachMarkHighlight>[];
    final attempts = step.waitForTarget ? 40 : 8;

    if (targets.isNotEmpty) {
      final primary = targets.first;
      await _waitForTargetRect(
        primary.key,
        inflate: primary.inflate,
        attempts: attempts,
      );
      if (!mounted || prepareToken != _productTourPrepareToken) {
        return;
      }
      final primaryContext = primary.key.currentContext;
      if (primaryContext != null && primaryContext.mounted) {
        await Scrollable.ensureVisible(
          primaryContext,
          duration: const Duration(milliseconds: 300),
          alignment: 0.18,
          curve: Curves.easeOutCubic,
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted || prepareToken != _productTourPrepareToken) {
        return;
      }
      for (final target in targets) {
        final rect = _rectForKey(target.key, inflate: target.inflate);
        if (rect != null) {
          highlights.add(
            AppCoachMarkHighlight(rect: rect, radius: target.radius),
          );
        }
      }
    }

    if (!mounted || prepareToken != _productTourPrepareToken) {
      return;
    }

    AnalyticsService.instance.track(
      'product_tour_step_viewed',
      properties: {
        'step': step.id.name,
        'index': index,
      },
    );

    setState(() {
      _productTourStepIndex = index;
      _productTourHighlights = highlights;
      _productTourChromeVisible = true;
      _productTourBusy = false;
    });
    unawaited(_productTourPrefs.saveProgress(step.id));
  }

  Future<void> _openMissionsFromProductTour() async {
    if (!_productTourVisible || _productTourBusy) {
      return;
    }
    if (_currentProductTourStep.id != HomeShellProductTourStepId.more) {
      await _goToTab(AppMainBottomTab.missions);
      return;
    }
    final missionsIndex = homeShellProductTourSteps.indexWhere(
      (step) => step.id == HomeShellProductTourStepId.missions,
    );
    if (missionsIndex < 0) {
      return;
    }
    await _prepareProductTourStep(missionsIndex);
  }

  Future<void> _onProductTourNext() async {
    if (_manualGuidedTourId != null) {
      if (_productTourBusy) {
        return;
      }
      await _onManualGuidedTourNext();
      return;
    }
    final nextIndex = _productTourStepIndex + 1;
    final isLastStep = nextIndex >= homeShellProductTourSteps.length;
    // Concluir nao pode ser engolido por busy preso de um prepare anterior.
    if (_productTourBusy && !isLastStep) {
      return;
    }
    if (_currentProductTourStep.id == HomeShellProductTourStepId.more) {
      await _openMissionsFromProductTour();
      return;
    }
    if (isLastStep) {
      await _finishProductTour(completed: true);
      return;
    }
    await _prepareProductTourStep(nextIndex);
  }

  ManualGuidedTourStep get _currentManualGuidedStep {
    return _manualGuidedSteps[_productTourStepIndex];
  }

  GlobalKey? _manualGuidedKeyFor(String targetId) {
    return switch (targetId) {
      ManualGuidedTourTargetIds.workoutDestination =>
        ManualGuidedTourTargets.workoutDestination,
      ManualGuidedTourTargetIds.profileDestination =>
        ManualGuidedTourTargets.profileDestination,
      ManualGuidedTourTargetIds.remindersDestination =>
        ManualGuidedTourTargets.remindersDestination,
      ManualGuidedTourTargetIds.notificationsDestination =>
        ManualGuidedTourTargets.notificationsDestination,
      ManualGuidedTourTargetIds.workoutPlanCard =>
        ManualGuidedTourTargets.workoutPlanCard,
      ManualGuidedTourTargetIds.workoutImportButton =>
        ManualGuidedTourTargets.workoutImportButton,
      ManualGuidedTourTargetIds.workoutAddExercise =>
        ManualGuidedTourTargets.workoutAddExercise,
      ManualGuidedTourTargetIds.profileBanner =>
        ManualGuidedTourTargets.profileBanner,
      ManualGuidedTourTargetIds.profileManual =>
        ManualGuidedTourTargets.profileManual,
      ManualGuidedTourTargetIds.remindersList =>
        ManualGuidedTourTargets.remindersList,
      ManualGuidedTourTargetIds.notificationsList =>
        ManualGuidedTourTargets.notificationsList,
      ManualGuidedTourTargetIds.waterCard => ManualGuidedTourTargets.waterCard,
      ManualGuidedTourTargetIds.stepsCard => ManualGuidedTourTargets.stepsCard,
      ManualGuidedTourTargetIds.weightCard => ManualGuidedTourTargets.weightCard,
      _ => null,
    };
  }

  Future<void> _openManualGuidedOverlay(ManualGuidedTourOverlay overlay) {
    return switch (overlay) {
      ManualGuidedTourOverlay.profile => _openProfile(),
      ManualGuidedTourOverlay.reminders => _openReminders(),
      ManualGuidedTourOverlay.notifications => _openNotifications(),
      ManualGuidedTourOverlay.support => _openSupport(),
    };
  }

  Future<void> _prepareManualGuidedTourStep(int index) async {
    if (!mounted ||
        index < 0 ||
        index >= _manualGuidedSteps.length ||
        _manualGuidedTourId == null) {
      return;
    }

    final prepareToken = ++_productTourPrepareToken;
    final step = _manualGuidedSteps[index];
    setState(() {
      _productTourBusy = true;
      _productTourChromeVisible = false;
      _productTourHighlights = const <AppCoachMarkHighlight>[];
      _productTourStepIndex = index;
    });

    if (step.kind == ManualGuidedTourStepKind.openMore) {
      if (!_isMoreMenuOpen) {
        setState(() => _isMoreMenuOpen = true);
      }
      await Future<void>.delayed(const Duration(milliseconds: 450));
    } else if (step.kind == ManualGuidedTourStepKind.tab && step.tab != null) {
      setState(() => _isMoreMenuOpen = false);
      await _goToTab(step.tab!);
      await Future<void>.delayed(
        Duration(milliseconds: step.waitForTarget ? 280 : 160),
      );
    } else if (step.kind == ManualGuidedTourStepKind.openOverlay &&
        step.overlay != null) {
      setState(() => _isMoreMenuOpen = false);
      if (_overlayDestination == AppMainOverlayDestination.none ||
          (step.overlay == ManualGuidedTourOverlay.profile &&
              _overlayDestination != AppMainOverlayDestination.profile) ||
          (step.overlay == ManualGuidedTourOverlay.reminders &&
              _overlayDestination != AppMainOverlayDestination.reminders) ||
          (step.overlay == ManualGuidedTourOverlay.notifications &&
              _overlayDestination != AppMainOverlayDestination.notifications)) {
        unawaited(_openManualGuidedOverlay(step.overlay!));
        await Future<void>.delayed(const Duration(milliseconds: 420));
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 160));
    }

    if (!mounted || prepareToken != _productTourPrepareToken) {
      return;
    }

    final highlights = <AppCoachMarkHighlight>[];
    final attempts = step.waitForTarget ? 40 : 8;
    for (final targetId in step.targetIds) {
      final key = _manualGuidedKeyFor(targetId);
      if (key == null) {
        continue;
      }
      await _waitForTargetRect(
        key,
        inflate: step.highlightInflate,
        attempts: attempts,
      );
      if (!mounted || prepareToken != _productTourPrepareToken) {
        return;
      }
      final targetContext = key.currentContext;
      if (targetContext != null && targetContext.mounted) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 280),
          alignment: step.scrollAlignment,
          curve: Curves.easeOutCubic,
        );
        await Future<void>.delayed(const Duration(milliseconds: 320));
      }
      if (!mounted || prepareToken != _productTourPrepareToken) {
        return;
      }
      final rect = _rectForKey(key, inflate: step.highlightInflate);
      if (rect != null) {
        highlights.add(
          AppCoachMarkHighlight(
            rect: rect,
            radius: step.highlightRadius,
          ),
        );
      }
    }

    if (!mounted || prepareToken != _productTourPrepareToken) {
      return;
    }

    setState(() {
      _productTourStepIndex = index;
      _productTourHighlights = highlights;
      _productTourChromeVisible = true;
      _productTourBusy = false;
    });
  }

  bool get _isManualGuidedTourActive =>
      _productTourVisible && _manualGuidedTourId != null;

  bool get _isAnyTourActive => _productTourVisible;

  bool get _isProductTourMoreStep =>
      _productTourVisible &&
      _manualGuidedTourId == null &&
      !_productTourBusy &&
      _currentProductTourStep.id == HomeShellProductTourStepId.more &&
      _currentProductTourStep.allowHighlightTap;

  bool _manualGuidedAllowsTab(AppMainBottomTab tab) {
    if (!_isManualGuidedTourActive || _productTourBusy) {
      return false;
    }
    final step = _currentManualGuidedStep;
    return step.allowHighlightTap && step.tab == tab;
  }

  bool _manualGuidedAllowsOverlay(ManualGuidedTourOverlay overlay) {
    if (!_isManualGuidedTourActive || _productTourBusy) {
      return false;
    }
    final step = _currentManualGuidedStep;
    return step.allowHighlightTap && step.overlay == overlay;
  }

  Future<void> _advanceManualGuidedAfterDestination() async {
    final nextIndex = _productTourStepIndex + 1;
    if (nextIndex >= _manualGuidedSteps.length) {
      await _finishProductTour(completed: true);
      return;
    }
    await _prepareManualGuidedTourStep(nextIndex);
  }

  Future<void> _onManualGuidedTourNext() async {
    if (_productTourBusy || _manualGuidedTourId == null) {
      return;
    }
    final step = _currentManualGuidedStep;

    if (step.kind == ManualGuidedTourStepKind.openMore) {
      setState(() => _isMoreMenuOpen = false);
      if (step.tab != null) {
        await _goToTab(step.tab!);
        await Future<void>.delayed(const Duration(milliseconds: 220));
      } else if (step.overlay != null) {
        unawaited(_openManualGuidedOverlay(step.overlay!));
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      await _advanceManualGuidedAfterDestination();
      return;
    }

    if (step.allowHighlightTap &&
        step.kind == ManualGuidedTourStepKind.tab &&
        step.tab != null) {
      await _goToTab(step.tab!);
      await _advanceManualGuidedAfterDestination();
      return;
    }

    if (step.allowHighlightTap &&
        step.kind == ManualGuidedTourStepKind.openOverlay &&
        step.overlay != null) {
      unawaited(_openManualGuidedOverlay(step.overlay!));
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await _advanceManualGuidedAfterDestination();
      return;
    }

    final nextIndex = _productTourStepIndex + 1;
    if (nextIndex >= _manualGuidedSteps.length) {
      await _finishProductTour(completed: true);
      return;
    }
    await _prepareManualGuidedTourStep(nextIndex);
  }

  Future<void> _finishProductTour({required bool completed}) async {
    // Nao depende de !_productTourBusy: prepare cancelado podia deixar busy true
    // e engolir o Concluir sem abrir o modal.
    if (!_productTourVisible) {
      return;
    }
    final isReplay = _productTourIsReplay;
    final manualTourId = _manualGuidedTourId;
    final stepIndex = _productTourStepIndex;
    _productTourPrepareToken += 1;
    setState(() {
      _productTourBusy = true;
      _productTourVisible = false;
      _productTourChromeVisible = false;
      _productTourHighlights = const <AppCoachMarkHighlight>[];
      _isMoreMenuOpen = false;
      _productTourIsReplay = false;
      _manualGuidedTourId = null;
      _manualGuidedSteps = const <ManualGuidedTourStep>[];
    });
    if (manualTourId != null) {
      AnalyticsService.instance.track(
        completed
            ? 'manual_guided_tour_completed'
            : 'manual_guided_tour_skipped',
        properties: {
          'tour': manualTourId.name,
          'step_index': stepIndex,
        },
      );
      if (mounted && completed) {
        AppToast.success(context, message: 'Tutorial guiado concluído.');
      }
      if (mounted) {
        setState(() => _productTourBusy = false);
      }
      return;
    }
    AnalyticsService.instance.track(
      completed ? 'product_tour_completed' : 'product_tour_skipped',
      properties: {
        'step_index': stepIndex,
        'step': homeShellProductTourSteps[stepIndex.clamp(
          0,
          homeShellProductTourSteps.length - 1,
        )].id.name,
        'replay': isReplay,
      },
    );
    unawaited(() async {
      try {
        if (isReplay) {
          await _productTourPrefs.clearProgress();
        } else {
          await _productTourPrefs.markCompleted();
        }
      } catch (_) {}
    }());
    if (!mounted) {
      return;
    }
    if (!completed) {
      await _goToTab(AppMainBottomTab.home);
      _scrollHomeToTopSoon();
      if (mounted) {
        setState(() => _productTourBusy = false);
      }
      return;
    }
    if (isReplay) {
      AppToast.success(context, message: 'Tour inicial concluído de novo.');
      await _goToTab(AppMainBottomTab.home);
      _scrollHomeToTopSoon();
      if (mounted) {
        setState(() => _productTourBusy = false);
      }
      return;
    }

    // Modal antes de trocar de aba: navegacao concorrente engolia o dialog.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    try {
      await HomeProductTourCongratsDialog.show(context);
    } catch (_) {}
    if (!mounted) {
      return;
    }
    await _goToTab(AppMainBottomTab.home);
    _scrollHomeToTopSoon();
    if (mounted) {
      setState(() => _productTourBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nestedCanPop = _nestedNavigatorKey.currentState?.canPop() ?? false;
    final navOverlap =
        homeShellBottomNavBodyHeight +
        homeShellBottomNavFloatingGap +
        MediaQuery.viewPaddingOf(context).bottom;
    final isManualTour =
        _productTourVisible && _manualGuidedTourId != null;
    final productTourStep =
        _productTourVisible && !isManualTour ? _currentProductTourStep : null;
    final manualTourStep = isManualTour ? _currentManualGuidedStep : null;
    final coachTitle = manualTourStep?.title ?? productTourStep?.title;
    final coachDescription =
        manualTourStep?.description ?? productTourStep?.description;
    final stepCount = isManualTour
        ? _manualGuidedSteps.length
        : homeShellProductTourSteps.length;
    final isLastTourStep = _productTourStepIndex >= stepCount - 1;
    final allowTourHighlightTap =
        ((manualTourStep?.allowHighlightTap ?? false) ||
            (productTourStep?.allowHighlightTap ?? false)) &&
        _productTourChromeVisible;
    final tourNextLabel = isLastTourStep
        ? 'Concluir'
        : (manualTourStep?.nextLabel ??
              productTourStep?.nextLabel ??
              'Próximo');
    final coachTooltipPlacement = manualTourStep != null
        ? (manualTourStep.tooltipAbove
              ? AppCoachMarkTooltipPlacement.above
              : AppCoachMarkTooltipPlacement.below)
        : switch (productTourStep?.tooltipPlacement) {
            HomeShellProductTourTooltipPlacement.above =>
              AppCoachMarkTooltipPlacement.above,
            HomeShellProductTourTooltipPlacement.below =>
              AppCoachMarkTooltipPlacement.below,
            HomeShellProductTourTooltipPlacement.auto || null =>
              AppCoachMarkTooltipPlacement.auto,
          };

    return HomeStepsWeightScope(
      controller: _stepsWeightController,
      child: HomeShellLayout(
        navOverlap: navOverlap,
        child: PopScope(
          canPop: !nestedCanPop && !_productTourVisible,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            if (_productTourVisible) {
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
                      child: KeyedSubtree(
                        key: _tourContentKey,
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
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        ignoring: _productTourVisible && !allowTourHighlightTap,
                        child: AppMainBottomNavigation(
                          activeTab: _activeTab,
                          overlayDestination: _overlayDestination,
                          isMoreMenuOpen: _isMoreMenuOpen,
                          suppressMoreScrim: _productTourVisible,
                          performanceTabKey: _performanceTabKey,
                          homeTabKey: _homeTabKey,
                          socialTabKey: _socialTabKey,
                          moreTabKey: _moreTabKey,
                          missionsDestinationKey: _missionsDestinationKey,
                          workoutDestinationKey:
                              ManualGuidedTourTargets.workoutDestination,
                          profileDestinationKey:
                              ManualGuidedTourTargets.profileDestination,
                          remindersDestinationKey:
                              ManualGuidedTourTargets.remindersDestination,
                          notificationsDestinationKey:
                              ManualGuidedTourTargets.notificationsDestination,
                          morePanelKey: _morePanelKey,
                          moreBundleKey: _moreBundleKey,
                          centerActionKey: _centerActionKey,
                          onMoreTap: () {
                            if (_isAnyTourActive) {
                              return;
                            }
                            setState(() {
                              _isMoreMenuOpen = !_isMoreMenuOpen;
                            });
                          },
                          onPerformanceTap: () {
                            if (_isAnyTourActive) {
                              return;
                            }
                            unawaited(_goToTab(AppMainBottomTab.performance));
                          },
                          onWorkoutTap: () {
                            if (_isManualGuidedTourActive) {
                              if (_manualGuidedAllowsTab(
                                AppMainBottomTab.workout,
                              )) {
                                unawaited(_onManualGuidedTourNext());
                              }
                              return;
                            }
                            if (_isAnyTourActive) {
                              return;
                            }
                            unawaited(_goToTab(AppMainBottomTab.workout));
                          },
                          onNotificationsTap: () {
                            if (_isManualGuidedTourActive) {
                              if (_manualGuidedAllowsOverlay(
                                ManualGuidedTourOverlay.notifications,
                              )) {
                                unawaited(_onManualGuidedTourNext());
                              }
                              return;
                            }
                            if (_isAnyTourActive) {
                              return;
                            }
                            unawaited(_openNotifications());
                          },
                          onRemindersTap: () {
                            if (_isManualGuidedTourActive) {
                              if (_manualGuidedAllowsOverlay(
                                ManualGuidedTourOverlay.reminders,
                              )) {
                                unawaited(_onManualGuidedTourNext());
                              }
                              return;
                            }
                            if (_isAnyTourActive) {
                              return;
                            }
                            unawaited(_openReminders());
                          },
                          onSupportTap: () {
                            if (_isAnyTourActive) {
                              return;
                            }
                            unawaited(_openSupport());
                          },
                          onStoreTap: () {
                            if (_isAnyTourActive) {
                              return;
                            }
                            unawaited(_openStore());
                          },
                          onProfileTap: () {
                            if (_isManualGuidedTourActive) {
                              if (_manualGuidedAllowsOverlay(
                                ManualGuidedTourOverlay.profile,
                              )) {
                                unawaited(_onManualGuidedTourNext());
                              }
                              return;
                            }
                            if (_isAnyTourActive) {
                              return;
                            }
                            unawaited(_openProfile());
                          },
                          onHomeTap: () {
                            if (_isAnyTourActive) {
                              return;
                            }
                            unawaited(_goToTab(AppMainBottomTab.home));
                          },
                          onMissionsTap: () {
                            if (_isManualGuidedTourActive) {
                              return;
                            }
                            if (_isProductTourMoreStep || _productTourVisible) {
                              unawaited(_openMissionsFromProductTour());
                              return;
                            }
                            unawaited(_goToTab(AppMainBottomTab.missions));
                          },
                          onSocialTap: () {
                            if (_isAnyTourActive) {
                              return;
                            }
                            unawaited(_goToTab(AppMainBottomTab.social));
                          },
                          onCenterActionTap: () {
                            if (_isAnyTourActive) {
                              return;
                            }
                            unawaited(_openFoodCapture());
                          },
                        ),
                      ),
                    ),
                    if (coachTitle != null && coachDescription != null)
                      Positioned.fill(
                        child: AppCoachMarkOverlay(
                          key: ValueKey(
                            'coach-tour-${_manualGuidedTourId?.name ?? 'product'}-'
                            '$_productTourStepIndex-'
                            '${_productTourChromeVisible ? 'on' : 'off'}',
                          ),
                          title: coachTitle,
                          description: coachDescription,
                          stepIndex: _productTourStepIndex,
                          stepCount: stepCount,
                          highlights: _productTourHighlights,
                          allowHighlightTap: allowTourHighlightTap,
                          showChrome: _productTourChromeVisible,
                          tooltipPlacement: coachTooltipPlacement,
                          nextLabel: tourNextLabel,
                          onNext: () => unawaited(_onProductTourNext()),
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
