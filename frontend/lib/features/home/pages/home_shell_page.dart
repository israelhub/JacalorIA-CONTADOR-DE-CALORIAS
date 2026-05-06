import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_main_bottom_navigation.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../food_analysis/pages/food_capture_page.dart';
import '../../missions/pages/missions_page.dart';
import '../../performance/pages/performance_page.dart';
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

  final AppMainBottomTab initialTab;
  final Widget? performancePage;
  final Widget? homePage;
  final Widget? missionsPage;
  final Widget? socialPage;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  static const int _performanceIndex = 0;
  static const int _homeIndex = 1;
  static const int _missionsIndex = 2;
  static const int _socialIndex = 3;

  late int _currentIndex;
  late DateTime _selectedHomeDate;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = _tabToIndex(widget.initialTab);
    _selectedHomeDate = normalizeHomeDate(DateTime.now());
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  Future<void> _goToTab(AppMainBottomTab tab) async {
    final nextIndex = _tabToIndex(tab);
    if (nextIndex == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = nextIndex;
    });

    await _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openFoodCapture() async {
    await context.pushSlidePage(const FoodCapturePage());
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
          });
        },
        children: [
          widget.performancePage ??
              PerformancePage(onDateSelected: _goToHomeDate),
          widget.homePage ??
              HomePage(
                initialSelectedDate: _selectedHomeDate,
                onSelectedDateChanged: (date) {
                  setState(() {
                    _selectedHomeDate = normalizeHomeDate(date);
                  });
                },
              ),
          widget.missionsPage ?? const MissionsPage(),
          widget.socialPage ?? const SocialPage(),
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
