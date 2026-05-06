import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/app_page_route.dart';

import '../../food_analysis/models/food_meal_record.dart';
import '../../food_analysis/pages/food_capture_page.dart';
import '../../food_analysis/pages/food_meal_details_page.dart';
import '../../auth/pages/login_page.dart';
import '../helpers/home_date_helpers.dart';
import '../helpers/home_greeting_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_dashed_action_button.dart';
import '../services/meal_service.dart';
import '../widgets/home_daily_goal_with_mascot.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../widgets/home_meal_card.dart';
import '../../auth/service/auth_service.dart';
import '../../profile/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  HomePage({
    super.key,
    MealService? mealService,
    AuthService? authService,
    this.initialSelectedDate,
    this.onSelectedDateChanged,
  }) : _mealService = mealService ?? const MealService(),
       _authService = authService ?? AuthService();

  static const _mealAsset =
      'assets/images/smiling green cartoon crocodile@2x.webp';
  static const _mascotIdleVideoAsset =
      'assets/videos/jaca_video_padrao_mobile_fast.webp';
  static const _mascotSadVideoAsset =
      'assets/videos/jaca_triste_mobile_fast.webp';
  static const _mascotScaredVideoAsset =
      'assets/videos/jaca_assustado_mobile_fast.webp';
  static const _mascotCelebrationVideoAsset =
      'assets/videos/jaca_feliz_mobile_fast.webp';
  static const _mealCardHeight =
      AppSpacing.huge + AppSpacing.xxxl + AppSpacing.md - 1;
  static const _newAccountFirstHomeAccessKeyPrefix =
      'new_account_first_home_access_';

  final MealService _mealService;
  final AuthService _authService;
  final DateTime? initialSelectedDate;
  final ValueChanged<DateTime>? onSelectedDateChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<FoodMealRecord> _records = <FoodMealRecord>[];
  Map<String, dynamic>? _userProfile;
  bool _isDataLoading = true;
  bool _playMascotCelebration = false;
  bool _isFirstHomeAccess = false;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = normalizeHomeDate(
      widget.initialSelectedDate ?? DateTime.now(),
    );
    _loadData();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialSelectedDate != oldWidget.initialSelectedDate &&
        widget.initialSelectedDate != null) {
      _selectedDate = normalizeHomeDate(widget.initialSelectedDate!);
    }
  }

  Future<void> _redirectToLoginPage({String? errorMessage}) async {
    await widget._authService.signOut();
    if (!mounted) {
      return;
    }

    context.pushAndRemoveUntilSlidePage(
      LoginPage(initialErrorMessage: errorMessage),
      (route) => false,
    );
  }

  Future<void> _loadData() async {
    if (AuthService.globalToken == null || AuthService.globalToken!.isEmpty) {
      await _redirectToLoginPage(
        errorMessage: 'Sessão inválida. Faça login novamente.',
      );
      return;
    }

    try {
      final results = await Future.wait([
        widget._mealService.fetchMeals(),
        widget._authService.fetchProfile(),
      ]);
      final meals = results[0] as List<FoodMealRecord>;
      final profile = results[1] as Map<String, dynamic>;
      final isFirstHomeAccess = await _consumeNewAccountFirstHomeAccess(
        profile,
      );

      try {
        await _precacheHomeImages(meals, profile);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _records.clear();
          _records.addAll(meals);
          _userProfile = profile.isNotEmpty ? profile : null;
          _isFirstHomeAccess = isFirstHomeAccess;
          _isDataLoading = false;
        });
      }
    } catch (e) {
      if (e.toString().contains('Sessão inválida')) {
        await _redirectToLoginPage(
          errorMessage: 'Sessão inválida. Faça login novamente.',
        );
        return;
      }

      await _redirectToLoginPage(errorMessage: e.toString());
      return;
    }
  }

  Future<void> _precacheHomeImages(
    List<FoodMealRecord> meals,
    Map<String, dynamic>? profile,
  ) async {
    if (!mounted) {
      return;
    }

    final providers = <ImageProvider<Object>>[
      const AssetImage(HomePage._mealAsset),
    ];

    final avatarUrl =
        profile?['avatarUrl'] as String? ?? profile?['avatar_url'] as String?;
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl.startsWith('http')) {
      providers.add(NetworkImage(avatarUrl));
    }

    for (final meal in meals) {
      if (meal.imageBytes != null) {
        providers.add(MemoryImage(meal.imageBytes!));
        continue;
      }

      final imageUrl = meal.imageUrl;
      if (imageUrl != null &&
          imageUrl.isNotEmpty &&
          imageUrl.startsWith('http')) {
        providers.add(NetworkImage(imageUrl));
        continue;
      }

      final imageAsset = meal.imageAsset;
      if (imageAsset != null && imageAsset.startsWith('assets/')) {
        providers.add(AssetImage(imageAsset));
      }
    }

    for (final provider in providers) {
      try {
        await precacheImage(provider, context);
      } catch (_) {}
    }
  }

  Future<bool> _consumeNewAccountFirstHomeAccess(
    Map<String, dynamic> profile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final rawUserId =
        profile['id'] ?? profile['email'] ?? profile['name'] ?? 'unknown-user';
    final userId = rawUserId.toString().trim();
    final storageKey = '${HomePage._newAccountFirstHomeAccessKeyPrefix}$userId';
    final isNewAccountFirstAccess = prefs.getBool(storageKey) ?? false;

    if (isNewAccountFirstAccess) {
      await prefs.remove(storageKey);
    }

    return isNewAccountFirstAccess;
  }

  String _resolveIdleMascotAsset() {
    final today = DateTime.now();
    final todayRecords = _records
        .where((record) {
          final createdAt = record.createdAt;
          return createdAt != null && isSameHomeDate(createdAt, today);
        })
        .toList(growable: false);

    final hasNoMealsToday = todayRecords.isEmpty;
    if (hasNoMealsToday && !_isFirstHomeAccess) {
      return HomePage._mascotSadVideoAsset;
    }

    final goalCalories = readHomeProfileInt(_userProfile, const [
      'daily_calorie_goal',
      'dailyCalorieGoal',
    ], fallback: 2000);
    final consumedCalories = todayRecords.fold<int>(
      0,
      (sum, record) => sum + record.calories,
    );

    if (consumedCalories > goalCalories) {
      return HomePage._mascotScaredVideoAsset;
    }

    return HomePage._mascotIdleVideoAsset;
  }

  bool _isCalorieGoalExceededForDate({
    required DateTime date,
    FoodMealRecord? extraRecord,
  }) {
    final normalizedDate = normalizeHomeDate(date);
    final dailyRecords = _records
        .where((record) {
          final createdAt = record.createdAt;
          return createdAt != null && isSameHomeDate(createdAt, normalizedDate);
        })
        .toList(growable: false);

    var consumedCalories = dailyRecords.fold<int>(
      0,
      (sum, record) => sum + record.calories,
    );

    if (extraRecord != null) {
      consumedCalories += extraRecord.calories;
    }

    final goalCalories = readHomeProfileInt(_userProfile, const [
      'daily_calorie_goal',
      'dailyCalorieGoal',
    ], fallback: 2000);

    return consumedCalories > goalCalories;
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return const _HomeBodySkeleton();
    }

    return _HomeBody(
      records: _records,
      userProfile: _userProfile,
      onAddMealPressed: _openFoodCapture,
      onAvatarTap: _openProfile,
      onMealTap: _openMealDetails,
      selectedDate: _selectedDate,
      onSelectedDateTap: _pickSelectedDate,
      playMascotCelebration: _playMascotCelebration,
      idleMascotVideoAsset: _resolveIdleMascotAsset(),
      mascotCelebrationVideoAsset: HomePage._mascotCelebrationVideoAsset,
      onMascotCelebrationCompleted: _handleMascotCelebrationCompleted,
    );
  }

  void _handleMascotCelebrationCompleted() {
    if (!_playMascotCelebration || !mounted) {
      return;
    }

    setState(() {
      _playMascotCelebration = false;
    });
  }

  Future<void> _pickSelectedDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        final colorScheme = baseTheme.colorScheme.copyWith(
          primary: AppColors.action500,
          onPrimary: AppColors.surface,
          secondary: AppColors.action500,
          onSecondary: AppColors.surface,
          surface: AppColors.surface,
          onSurface: AppColors.brand900Variant,
        );

        return Theme(
          data: baseTheme.copyWith(
            colorScheme: colorScheme,
            datePickerTheme: baseTheme.datePickerTheme.copyWith(
              backgroundColor: AppColors.surface,
              headerBackgroundColor: AppColors.surface,
              headerForegroundColor: AppColors.brand900Variant,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.black;
                }
                return AppColors.brand900Variant;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.action500;
                }
                return Colors.transparent;
              }),
              todayForegroundColor: const WidgetStatePropertyAll(
                AppColors.action500,
              ),
              todayBorder: const BorderSide(color: AppColors.action500),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: AppColors.action500,
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: AppColors.action500,
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    await _setSelectedDate(pickedDate);
  }

  Future<void> _setSelectedDate(DateTime date) async {
    final normalized = normalizeHomeDate(date);
    if (isSameHomeDate(_selectedDate, normalized)) {
      return;
    }

    setState(() {
      _selectedDate = normalized;
    });

    widget.onSelectedDateChanged?.call(normalized);
  }

  Future<void> _openProfile() async {
    final hasUpdatedProfile = await context.pushSlidePage<bool>(
      ProfilePage(initialProfile: _userProfile),
    );

    if (hasUpdatedProfile == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _openFoodCapture() async {
    final record = await context.pushSlidePage<FoodMealRecord>(
      const FoodCapturePage(),
    );

    if (record == null || !mounted) {
      return;
    }

    final recordDate = normalizeHomeDate(record.createdAt ?? DateTime.now());
    final recordId = (record.id ?? '').trim();
    final shouldPlayCelebration = !_isCalorieGoalExceededForDate(
      date: recordDate,
      extraRecord: record,
    );

    setState(() {
      _selectedDate = recordDate;
      _playMascotCelebration = shouldPlayCelebration;

      if (recordId.isNotEmpty) {
        _records.removeWhere((item) => (item.id ?? '').trim() == recordId);
      }

      _records.insert(0, record);
    });

    widget.onSelectedDateChanged?.call(recordDate);
  }

  Future<void> _openMealDetails(FoodMealRecord record) async {
    final updatedRecord = await context.pushSlidePage<FoodMealRecord>(
      FoodMealDetailsPage(record: record, userProfile: _userProfile),
    );

    if (!mounted || updatedRecord == null) {
      return;
    }

    final updatedId = (updatedRecord.id ?? '').trim();

    setState(() {
      if (updatedId.isNotEmpty) {
        _records.removeWhere((item) => (item.id ?? '').trim() == updatedId);
      }
      if (updatedRecord.status != 'deleted') {
        _records.insert(0, updatedRecord);
      }
    });
  }
}

class _HomeBodySkeleton extends StatelessWidget {
  const _HomeBodySkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                const _HomeHeaderSkeleton(),
                const SizedBox(height: AppSpacing.xxxl),
                const _HomeGoalSkeleton(),
                const SizedBox(height: AppSpacing.xl),
                const _MealsHeaderSkeleton(),
                const SizedBox(height: AppSpacing.sm),
                const _AddMealActionSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const _MealCardSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const _MealCardSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const _MealCardSkeleton(),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeaderSkeleton extends StatelessWidget {
  const _HomeHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBox(height: AppSpacing.lg, width: 140),
              SizedBox(height: AppSpacing.sm),
              AppSkeletonBox(height: AppSpacing.xxl, width: 120),
            ],
          ),
        ),
        AppSkeletonBox(
          width: AppSpacing.huge + AppSpacing.xs,
          height: AppSpacing.huge + AppSpacing.xs,
          borderRadius: AppRadius.pill,
        ),
      ],
    );
  }
}

class _HomeGoalSkeleton extends StatelessWidget {
  const _HomeGoalSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonBox(height: 190, borderRadius: AppRadius.lg);
  }
}

class _MealsHeaderSkeleton extends StatelessWidget {
  const _MealsHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: AppSkeletonBox(height: AppSpacing.lg)),
        SizedBox(width: AppSpacing.md),
        AppSkeletonBox(height: AppSpacing.md, width: 90),
      ],
    );
  }
}

class _AddMealActionSkeleton extends StatelessWidget {
  const _AddMealActionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonBox(
      height: HomePage._mealCardHeight,
      borderRadius: AppRadius.lg,
    );
  }
}

class _MealCardSkeleton extends StatelessWidget {
  const _MealCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonBox(
      height: HomePage._mealCardHeight,
      borderRadius: AppRadius.lg,
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.records,
    required this.onAddMealPressed,
    required this.onMealTap,
    required this.selectedDate,
    required this.onSelectedDateTap,
    required this.playMascotCelebration,
    required this.idleMascotVideoAsset,
    required this.mascotCelebrationVideoAsset,
    required this.onMascotCelebrationCompleted,
    this.userProfile,
    this.onAvatarTap,
  });

  final List<FoodMealRecord> records;
  final VoidCallback onAddMealPressed;
  final Future<void> Function(FoodMealRecord record) onMealTap;
  final DateTime selectedDate;
  final VoidCallback onSelectedDateTap;
  final bool playMascotCelebration;
  final String idleMascotVideoAsset;
  final String mascotCelebrationVideoAsset;
  final VoidCallback onMascotCelebrationCompleted;
  final Map<String, dynamic>? userProfile;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    _Header(userProfile: userProfile, onAvatarTap: onAvatarTap),
                    const SizedBox(height: AppSpacing.xxxl),
                    HomeDailyGoalWithMascot(
                      mascotAsset: HomePage._mealAsset,
                      idleMascotVideoAsset: idleMascotVideoAsset,
                      mascotVideoAsset: mascotCelebrationVideoAsset,
                      playMascotVideo: playMascotCelebration,
                      onMascotVideoCompleted: onMascotCelebrationCompleted,
                      records: records,
                      userProfile: userProfile,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _MealsHeader(
                      selectedDate: selectedDate,
                      onTap: onSelectedDateTap,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _AddMealAction(onTap: onAddMealPressed),
                    const SizedBox(height: AppSpacing.lg),
                    ...records
                        .where((record) {
                          final createdAt = record.createdAt;
                          if (createdAt == null) {
                            return true;
                          }

                          return isSameHomeDate(createdAt, selectedDate);
                        })
                        .toList(growable: false)
                        .asMap()
                        .entries
                        .expand((entry) {
                          final index = entry.key;
                          final record = entry.value;

                          return <Widget>[
                            HomeMealCard(
                              cardKey: ValueKey('home-meal-card-$index'),
                              title: record.title,
                              description: record.description,
                              kcal: record.kcalLabel,
                              time: record.timeLabel,
                              imageAsset: record.imageAsset,
                              imageBytes: record.imageBytes,
                              imageUrl: record.imageUrl,
                              height: HomePage._mealCardHeight,
                              onTap: () => onMealTap(record),
                            ),
                            if (index != records.length - 1)
                              const SizedBox(height: AppSpacing.lg),
                          ];
                        }),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.userProfile, this.onAvatarTap});
  final Map<String, dynamic>? userProfile;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final rawName = userProfile?['name'] as String? ?? '';
    final trimmedName = rawName.trim();
    final firstName = trimmedName.isEmpty
        ? ''
        : trimmedName.split(RegExp(r'\s+')).first;
    final avatarUrl =
        userProfile?['avatarUrl'] as String? ??
        userProfile?['avatar_url'] as String?;
    final greeting = homeGreetingFor(DateTime.now());

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${greeting.emoji} ${greeting.label}',
                style: AppTextStyles.homeHello.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                firstName,
                style: AppTextStyles.homeUserName.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onAvatarTap,
          child: ClipOval(
            child: SizedBox(
              width: AppSpacing.huge + AppSpacing.xs,
              height: AppSpacing.huge + AppSpacing.xs,
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: AppColors.surfaceAlt,
                        child: Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : const ColoredBox(
                      color: AppColors.surfaceAlt,
                      child: Icon(Icons.person, color: AppColors.textSecondary),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MealsHeader extends StatelessWidget {
  const _MealsHeader({required this.selectedDate, required this.onTap});

  final DateTime selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Refeições do dia',
            style: AppTextStyles.homeSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              formatHomeDateLabel(selectedDate),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddMealAction extends StatelessWidget {
  const _AddMealAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppDashedActionButton(
      label: 'Adicionar refeição',
      onTap: onTap,
      height: HomePage._mealCardHeight,
      borderRadius: AppRadius.lg - AppSpacing.xs,
      labelStyle: AppTextStyles.homeAction.copyWith(color: AppColors.action500),
      leading: Container(
        width: AppSpacing.xxl + AppSpacing.xs,
        height: AppSpacing.xxl + AppSpacing.xs,
        decoration: const BoxDecoration(
          color: AppColors.action500,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '+',
          style: AppTextStyles.buttonMedium.copyWith(color: AppColors.surface),
        ),
      ),
    );
  }
}
