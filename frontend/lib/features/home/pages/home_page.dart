import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../avatar_frames/models/avatar_background_catalog.dart';
import '../../avatar_frames/models/avatar_frame_catalog.dart';
import '../../../shared/widgets/app_page_route.dart';

import '../../food_analysis/models/food_meal_record.dart';
import '../../food_analysis/pages/food_capture_page.dart';
import '../../food_analysis/pages/food_meal_details_page.dart';
import '../../auth/pages/login_page.dart';
import '../helpers/home_daily_goal_day_lock.dart';
import '../helpers/home_date_helpers.dart';
import '../helpers/home_goal_helpers.dart';
import '../helpers/home_greeting_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_ambient_page_glow.dart';
import '../../../shared/widgets/app_refresh_scroll_view.dart';
import '../services/meal_service.dart';
import '../widgets/home_daily_goal_with_mascot.dart';
import '../../../shared/widgets/app_confirm_modal.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/framed_avatar.dart';
import '../../workouts/helpers/workout_day_helpers.dart';
import '../../workouts/helpers/workout_formatters.dart';
import '../../workouts/models/workout_models.dart';
import '../../workouts/services/workout_service.dart';
import '../../workouts/widgets/workout_day_exercise_card.dart';
import '../../workouts/pages/workout_load_form_page.dart';
import '../../workouts/widgets/workout_form_sheets.dart';
import '../../workouts/widgets/workout_pick_exercise_sheet.dart';
import '../helpers/home_water_helpers.dart';
import '../models/home_water_models.dart';
import '../services/water_service.dart';
import '../widgets/home_add_choice_sheet.dart';
import '../widgets/home_add_water_sheet.dart';
import '../widgets/home_meal_card.dart';
import '../widgets/home_shell_layout.dart';
import '../widgets/home_steps_weight_row.dart';
import '../widgets/home_steps_weight_scope.dart';
import '../widgets/home_water_card.dart';
import '../widgets/home_week_date_selector.dart';
import '../../../core/notifications/meal_reminder_home_widget.dart';
import '../../auth/service/auth_service.dart';
import '../../profile/pages/profile_page.dart';
import '../../social/helpers/social_data_invalidator.dart';

class HomePage extends StatefulWidget {
  HomePage({
    super.key,
    MealService? mealService,
    AuthService? authService,
    WorkoutService? workoutService,
    WaterService? waterService,
    this.initialSelectedDate,
    this.onSelectedDateChanged,
    this.mealSyncVersion = 0,
    this.pendingSavedMeal,
  }) : _mealService = mealService ?? const MealService(),
       _authService = authService ?? AuthService(),
       _workoutService = workoutService ?? const WorkoutService(),
       _waterService = waterService ?? const WaterService();

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
  static const _mealCardHeight = HomeMealCard.defaultHeight;
  static const _homeAvatarSize = AppSpacing.huge + AppSpacing.xl;
  // Compensa a foto maior para o Jaca e o card ficarem no lugar da foto de 52.
  static const _goalCardTopGap =
      AppSpacing.xxxl - (_homeAvatarSize - (AppSpacing.huge + AppSpacing.md));
  static const _headerSideInset =
      AppSpacing.lg - AppSpacing.pageHorizontal;
  static const _newAccountFirstHomeAccessKeyPrefix =
      'new_account_first_home_access_';

  final MealService _mealService;
  final AuthService _authService;
  final WorkoutService _workoutService;
  final WaterService _waterService;
  final DateTime? initialSelectedDate;
  final ValueChanged<DateTime>? onSelectedDateChanged;
  final int mealSyncVersion;
  final FoodMealRecord? pendingSavedMeal;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final List<FoodMealRecord> _records = <FoodMealRecord>[];
  final Set<String> _loadedDateKeys = <String>{};
  WorkoutOverview _workouts = const WorkoutOverview(routines: []);
  WaterOverview _water = const WaterOverview();
  Map<String, dynamic>? _userProfile;
  HomeDailyGoalDaySnapshot? _dayGoalSnapshot;
  bool _isDataLoading = true;
  bool _playMascotCelebration = false;
  bool _isFirstHomeAccess = false;
  late DateTime _selectedDate;

  @override
  bool get wantKeepAlive => true;

  /// Meta/objetivo do dia (congelados na virada) quando a data selecionada é hoje.
  Map<String, dynamic>? get _goalUserProfile => applyHomeDailyGoalDaySnapshot(
    profile: _userProfile,
    snapshot: _dayGoalSnapshot,
    selectedDate: _selectedDate,
  );

  @override
  void initState() {
    super.initState();
    _selectedDate = normalizeHomeDate(
      widget.initialSelectedDate ?? DateTime.now(),
    );
    // Paint header immediately from session cache; meals still load below.
    final cachedUser = AuthService.globalUser;
    if (cachedUser != null && cachedUser.isNotEmpty) {
      _userProfile = Map<String, dynamic>.from(cachedUser);
    }
    _loadInitialData();
  }

  void _syncStepsWeightProfile(Map<String, dynamic>? profile) {
    final controller = HomeStepsWeightScope.maybeOf(context);
    if (controller == null) {
      return;
    }
    unawaited(controller.syncProfile(profile));
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mealSyncVersion != oldWidget.mealSyncVersion &&
        widget.pendingSavedMeal != null) {
      _applySavedMeal(widget.pendingSavedMeal!);
      return;
    }

    if (widget.initialSelectedDate != oldWidget.initialSelectedDate &&
        widget.initialSelectedDate != null) {
      final normalized = normalizeHomeDate(widget.initialSelectedDate!);
      if (isSameHomeDate(_selectedDate, normalized)) {
        return;
      }

      _selectedDate = normalized;
      // Calendário só atualizava a data; sem este fetch a Home ficava vazia.
      _loadMealsForDate(normalized);
    }
  }

  Future<void> _redirectToLoginPage({String? errorMessage}) async {
    await AuthService.signOut();
    if (!mounted) {
      return;
    }

    context.pushAndRemoveUntilSlidePage(
      LoginPage(initialErrorMessage: errorMessage),
      (route) => false,
    );
  }

  String _dateKey(DateTime date) {
    final normalized = normalizeHomeDate(date);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime _startOfNextDay(DateTime date) {
    final normalized = normalizeHomeDate(date);
    return DateTime(normalized.year, normalized.month, normalized.day + 1);
  }

  Future<void> _loadInitialData({bool forceRefreshDayGoal = false}) async {
    if (AuthService.globalToken == null || AuthService.globalToken!.isEmpty) {
      await _redirectToLoginPage(
        errorMessage: 'Sessão inválida. Faça login novamente.',
      );
      return;
    }

    try {
      final results = await Future.wait([
        widget._mealService.fetchMeals(
          startDate: _selectedDate,
          endDate: _startOfNextDay(_selectedDate),
        ),
        widget._authService.fetchProfile(forceRefresh: forceRefreshDayGoal),
        _fetchWorkouts(),
        _fetchWater(),
      ]);
      final meals = results[0] as List<FoodMealRecord>;
      final profile = results[1] as Map<String, dynamic>;
      final workouts = results[2] as WorkoutOverview;
      final water = results[3] as WaterOverview;
      var isFirstHomeAccess = false;
      try {
        isFirstHomeAccess = await _consumeNewAccountFirstHomeAccess(profile);
      } catch (_) {
        isFirstHomeAccess = false;
      }

      HomeDailyGoalDaySnapshot? dayGoalSnapshot;
      try {
        dayGoalSnapshot = await resolveHomeDailyGoalDaySnapshot(
          profile: profile.isNotEmpty ? profile : null,
          forceRefresh: forceRefreshDayGoal,
        );
      } catch (_) {
        dayGoalSnapshot = null;
      }

      if (mounted) {
        setState(() {
          _records.clear();
          _records.addAll(meals);
          _workouts = workouts;
          _water = water;
          _loadedDateKeys.add(_dateKey(_selectedDate));
          _userProfile = profile.isNotEmpty ? profile : null;
          _dayGoalSnapshot = dayGoalSnapshot;
          _isFirstHomeAccess = isFirstHomeAccess;
          _isDataLoading = false;
        });

        if (widget.pendingSavedMeal != null) {
          _applySavedMeal(widget.pendingSavedMeal!);
        }

        _scheduleHomeImagePrecache(meals, profile);
        _syncStepsWeightProfile(_userProfile);
        unawaited(
          MealReminderHomeWidget.sync(
            streakDays: readHomeProfileInt(profile, const [
              'streakDays',
              'streak_days',
            ]),
          ),
        );
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

  Future<void> _refreshData() async {
    if (AuthService.globalToken == null || AuthService.globalToken!.isEmpty) {
      return;
    }

    _loadedDateKeys.remove(_dateKey(_selectedDate));
    final mealsFuture = _loadMealsForDate(_selectedDate);
    final workoutsFuture = _reloadWorkouts();
    final waterFuture = _reloadWater();
    final stepsFuture =
        HomeStepsWeightScope.maybeOf(context)?.reloadSteps(quietly: true) ??
        Future<void>.value();

    try {
      final profile = await widget._authService.fetchProfile(
        forceRefresh: true,
      );
      HomeDailyGoalDaySnapshot? dayGoalSnapshot;
      try {
        dayGoalSnapshot = await resolveHomeDailyGoalDaySnapshot(
          profile: profile.isNotEmpty ? profile : null,
        );
      } catch (_) {
        dayGoalSnapshot = null;
      }
      if (mounted) {
        setState(() {
          _userProfile = profile.isNotEmpty ? profile : null;
          _dayGoalSnapshot = dayGoalSnapshot;
        });
        _syncStepsWeightProfile(_userProfile);
      }
    } catch (_) {}

    await Future.wait<void>([
      mealsFuture,
      workoutsFuture,
      waterFuture,
      stepsFuture,
    ]);
  }

  Future<WorkoutOverview> _fetchWorkouts() async {
    try {
      return await widget._workoutService.fetchWorkouts();
    } catch (_) {
      return const WorkoutOverview(routines: []);
    }
  }

  Future<void> _reloadWorkouts() async {
    final overview = await _fetchWorkouts();
    if (!mounted) {
      return;
    }
    setState(() {
      _workouts = overview;
    });
  }

  Future<WaterOverview> _fetchWater() async {
    try {
      final days = homeWaterChartDays(_selectedDate);
      return await widget._waterService.fetchWater(
        startDate: days.first,
        endDate: days.last,
      );
    } catch (_) {
      return const WaterOverview();
    }
  }

  Future<void> _reloadWater() async {
    final overview = await _fetchWater();
    if (!mounted) {
      return;
    }
    setState(() {
      _water = overview;
    });
  }

  Future<void> _loadMealsForDate(DateTime date) async {
    final normalizedDate = normalizeHomeDate(date);
    final dateKey = _dateKey(normalizedDate);
    if (_loadedDateKeys.contains(dateKey)) {
      return;
    }

    try {
      final meals = await widget._mealService.fetchMeals(
        startDate: normalizedDate,
        endDate: _startOfNextDay(normalizedDate),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _records.removeWhere((record) {
          final createdAt = record.createdAt;
          return createdAt != null && isSameHomeDate(createdAt, normalizedDate);
        });
        _records.addAll(meals);
        _records.sort((a, b) {
          final aCreated = a.createdAt;
          final bCreated = b.createdAt;
          if (aCreated == null && bCreated == null) {
            return 0;
          }
          if (aCreated == null) {
            return 1;
          }
          if (bCreated == null) {
            return -1;
          }
          return bCreated.compareTo(aCreated);
        });
        _loadedDateKeys.add(dateKey);
      });

      _scheduleHomeImagePrecache(meals, _userProfile);
    } catch (_) {}
  }

  void _scheduleHomeImagePrecache(
    List<FoodMealRecord> meals,
    Map<String, dynamic>? profile,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_precacheHomeImages(meals, profile));
    });
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

    final equippedFrameAsset = AvatarFrameCatalog.byId(
      AvatarFrameCatalog.equippedIdFromProfile(profile),
    )?.assetPath;
    if (equippedFrameAsset != null && equippedFrameAsset.isNotEmpty) {
      providers.add(AssetImage(equippedFrameAsset));
    }

    final backgroundAsset = AvatarBackgroundCatalog.assetPathForId(
      AvatarBackgroundCatalog.equippedBackgroundIdFromProfile(profile),
    );
    if (backgroundAsset != null && backgroundAsset.isNotEmpty) {
      providers.add(AssetImage(backgroundAsset));
    }

    final avatarUrl =
        profile?['avatarUrl'] as String? ?? profile?['avatar_url'] as String?;
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl.startsWith('http')) {
      providers.add(CachedNetworkImageProvider(avatarUrl));
    }

    // Decode only images likely to be visible above the fold. Preloading every
    // meal and every store frame competes with navigation animations on web.
    for (final meal in meals.take(4)) {
      if (meal.imageBytes != null) {
        providers.add(MemoryImage(meal.imageBytes!));
        continue;
      }

      final imageUrl = meal.imageUrl;
      if (imageUrl != null &&
          imageUrl.isNotEmpty &&
          imageUrl.startsWith('http')) {
        providers.add(CachedNetworkImageProvider(imageUrl));
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

  String _resolveIdleMascotAsset({required DateTime date}) {
    final normalizedDate = normalizeHomeDate(date);
    final selectedDateRecords = _records
        .where((record) {
          if (record.status.trim().toLowerCase() == 'deleted') {
            return false;
          }
          final createdAt = record.createdAt;
          return createdAt != null && isSameHomeDate(createdAt, normalizedDate);
        })
        .toList(growable: false);

    final goalProfile = applyHomeDailyGoalDaySnapshot(
      profile: _userProfile,
      snapshot: _dayGoalSnapshot,
      selectedDate: normalizedDate,
    );
    final goalCalories = readHomeProfileInt(goalProfile, const [
      'daily_calorie_goal',
      'dailyCalorieGoal',
    ], fallback: 2000);
    final consumedCalories = selectedDateRecords.fold<int>(
      0,
      (sum, record) => sum + record.calories,
    );

    final emotion = resolveHomeMascotEmotionForProfile(
      consumedCalories: consumedCalories,
      goalCalories: goalCalories,
      userProfile: goalProfile,
      hasMeals: selectedDateRecords.isNotEmpty,
      isFirstHomeAccess: _isFirstHomeAccess,
    );

    switch (emotion) {
      case HomeMascotEmotion.sad:
        return HomePage._mascotSadVideoAsset;
      case HomeMascotEmotion.scared:
        return HomePage._mascotScaredVideoAsset;
      case HomeMascotEmotion.happy:
        return HomePage._mascotCelebrationVideoAsset;
      case HomeMascotEmotion.idle:
        return HomePage._mascotIdleVideoAsset;
    }
  }

  bool _hasCalorieGoalReachedForDate({
    required DateTime date,
    FoodMealRecord? extraRecord,
  }) {
    final normalizedDate = normalizeHomeDate(date);
    final dailyRecords = _records
        .where((record) {
          if (record.status.trim().toLowerCase() == 'deleted') {
            return false;
          }
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

    final goalProfile = applyHomeDailyGoalDaySnapshot(
      profile: _userProfile,
      snapshot: _dayGoalSnapshot,
      selectedDate: normalizedDate,
    );
    final goalCalories = readHomeProfileInt(goalProfile, const [
      'daily_calorie_goal',
      'dailyCalorieGoal',
    ], fallback: 2000);

    return hasReachedCalorieGoalForProfile(
      consumedCalories: consumedCalories,
      goalCalories: goalCalories,
      userProfile: goalProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isDataLoading) {
      return const _HomeBodySkeleton();
    }

    return _HomeBody(
      records: _records,
      userProfile: _userProfile,
      goalUserProfile: _goalUserProfile,
      onAvatarTap: _openProfile,
      onWeightUpdated: _onWeightUpdated,
      onMealTap: _openMealDetails,
      onRefresh: _refreshData,
      selectedDate: _selectedDate,
      workoutEntries: workoutEntriesOnDate(
        routines: _workouts.routines,
        date: _selectedDate,
      ),
      onSelectedDateChanged: _setSelectedDate,
      onAddMealPressed: _openFoodCapture,
      onAddWorkoutPressed: _addWorkoutToDay,
      waterDays: fillHomeWaterDays(
        selectedDate: _selectedDate,
        millilitersByDate: _water.millilitersByDate,
      ),
      waterGoalMl: _water.goalMl,
      onAddWaterPressed: _addWater,
      onWorkoutTap: _editWorkoutEntry,
      onWorkoutDelete: _deleteWorkoutEntry,
      playMascotCelebration: _playMascotCelebration,
      idleMascotVideoAsset: _resolveIdleMascotAsset(date: _selectedDate),
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

  Future<void> _addWater() async {
    final amount = await showHomeAddWaterSheet(context);
    if (!mounted || amount == null) {
      return;
    }

    try {
      final result = await widget._waterService.addWater(
        milliliters: amount,
        recordedAt: _selectedDate,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _water = _water.replacingDay(result.day).copyWithGoal(result.goalMl);
      });
      AppToast.success(
        context,
        message: '${formatWaterVolume(amount)} adicionados.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _addWorkoutToDay() async {
    if (_workouts.routines.isEmpty) {
      AppToast.error(
        context,
        message: 'Monte uma ficha na aba Treino primeiro.',
      );
      return;
    }

    final routine = await showHomeWorkoutRoutineSheet(
      context,
      routines: _workouts.routines,
    );
    if (!mounted || routine == null) {
      return;
    }
    if (routine.exercises.isEmpty) {
      AppToast.error(context, message: 'Essa ficha ainda não tem exercícios.');
      return;
    }

    final remaining = remainingExercisesOnDate(
      routine: routine,
      date: _selectedDate,
    );
    final logged = routine.exercises
        .where((exercise) => remaining.every((item) => item.id != exercise.id))
        .toList();
    final picked = await showWorkoutPickExerciseSheet(
      context,
      routineName: routine.name,
      remaining: remaining,
      logged: logged,
    );
    if (!mounted || picked == null) {
      return;
    }
    await _upsertWorkoutLoad(picked);
  }

  Future<void> _editWorkoutEntry(WorkoutDayEntry entry) async {
    await _upsertWorkoutLoad(entry.exercise);
  }

  Future<void> _upsertWorkoutLoad(WorkoutExercise exercise) async {
    final draft = await context.pushSlidePage<WorkoutLoadDraft>(
      WorkoutLoadFormPage(
        exercise: exercise,
        recordedAt: _selectedDate,
        lockDate: true,
      ),
    );
    if (draft == null) {
      return;
    }

    try {
      final updated = await widget._workoutService.upsertLoad(
        exerciseId: exercise.id,
        weight: draft.weight,
        recordedAt: draft.recordedAt,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _workouts = _workouts.replacingExercise(updated);
      });
      AppToast.success(
        context,
        message: '${formatWorkoutWeight(draft.weight)} kg em ${exercise.name}.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _deleteWorkoutEntry(WorkoutDayEntry entry) async {
    final confirmed = await AppConfirmModal.show(
      context,
      title: 'Tirar ${entry.exercise.name} do dia?',
      message: 'O peso desse dia some, o exercício continua nas Fichas.',
      confirmLabel: 'Tirar',
      isDanger: true,
    );
    if (!confirmed) {
      return;
    }

    try {
      await widget._workoutService.deleteLoad(loadId: entry.load.id);
      await _reloadWorkouts();
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _setSelectedDate(DateTime date) async {
    final normalized = normalizeHomeDate(date);
    if (isSameHomeDate(_selectedDate, normalized)) {
      return;
    }

    setState(() {
      _selectedDate = normalized;
    });

    await Future.wait<void>([_loadMealsForDate(normalized), _reloadWater()]);
    widget.onSelectedDateChanged?.call(normalized);
  }

  Future<void> _openProfile() async {
    final hasUpdatedProfile = await context.pushSlidePage<bool>(
      ProfilePage(initialProfile: _userProfile),
    );

    if (hasUpdatedProfile == true && mounted) {
      await _loadInitialData(forceRefreshDayGoal: true);
    }
  }

  Future<void> _onWeightUpdated(Map<String, dynamic> updatedProfile) async {
    if (!mounted) {
      return;
    }

    final mergedProfile = <String, dynamic>{
      ...?_userProfile,
      ...updatedProfile,
      if (updatedProfile['weightUnit'] != null)
        'weight_unit': updatedProfile['weightUnit'],
    };

    HomeDailyGoalDaySnapshot? dayGoalSnapshot;
    try {
      dayGoalSnapshot = await resolveHomeDailyGoalDaySnapshot(
        profile: mergedProfile,
        forceRefresh: true,
      );
    } catch (_) {
      dayGoalSnapshot = _dayGoalSnapshot;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _userProfile = mergedProfile;
      _dayGoalSnapshot = dayGoalSnapshot;
    });
    _syncStepsWeightProfile(mergedProfile);
  }

  Future<void> _openFoodCapture() async {
    final record = await context.pushSlidePage<FoodMealRecord>(
      FoodCapturePage(
        recordedAt: resolveMealRecordedAt(selectedDate: _selectedDate),
      ),
      rootNavigator: true,
    );

    if (record == null || !mounted) {
      return;
    }

    _applySavedMeal(record);
  }

  void _applySavedMeal(FoodMealRecord record) {
    final recordDate = normalizeHomeDate(record.createdAt ?? DateTime.now());
    final recordId = (record.id ?? '').trim();
    final isDeleted = record.status.trim().toLowerCase() == 'deleted';

    if (isDeleted) {
      setState(() {
        if (recordId.isNotEmpty) {
          _records.removeWhere((item) => (item.id ?? '').trim() == recordId);
        }
        _isDataLoading = false;
      });
      SocialDataInvalidator.markDirty();
      return;
    }

    final shouldPlayCelebration = _hasCalorieGoalReachedForDate(
      date: recordDate,
      extraRecord: record,
    );

    setState(() {
      _selectedDate = recordDate;
      _playMascotCelebration = shouldPlayCelebration;
      _isDataLoading = false;

      if (recordId.isNotEmpty) {
        _records.removeWhere((item) => (item.id ?? '').trim() == recordId);
      }

      _records.insert(0, record);
      _loadedDateKeys.add(_dateKey(recordDate));
    });

    SocialDataInvalidator.markDirty();
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
      final index = updatedId.isEmpty
          ? -1
          : _records.indexWhere((item) => (item.id ?? '').trim() == updatedId);

      if (updatedRecord.status == 'deleted') {
        if (index >= 0) {
          _records.removeAt(index);
        }
        return;
      }

      if (index >= 0) {
        _records[index] = updatedRecord;
      } else {
        _records.insert(0, updatedRecord);
      }
    });

    SocialDataInvalidator.markDirty();
  }
}

class _HomeBodySkeleton extends StatelessWidget {
  const _HomeBodySkeleton();

  @override
  Widget build(BuildContext context) {
    final bottomInset = homeShellFabBottomInset(context);

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: AppAmbientPageBody(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.xxl,
              AppSpacing.pageHorizontal,
              bottomInset + AppSpacing.xxxl,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: HomePage._headerSideInset,
                  ),
                  child: _HomeHeaderSkeleton(),
                ),
                SizedBox(height: HomePage._goalCardTopGap),
                _HomeGoalSkeleton(),
                SizedBox(height: AppSpacing.xl),
                AppSkeletonBox(height: 64, borderRadius: AppRadius.md),
                SizedBox(height: AppSpacing.xl),
                _HomeSectionSkeleton(titleWidth: 110, itemCount: 2),
                SizedBox(height: AppSpacing.cardGap),
                _HomeSectionSkeleton(titleWidth: 90, itemCount: 1),
                SizedBox(height: AppSpacing.cardGap),
                AppSkeletonBox(
                  height: HomeWaterCard.cardHeight,
                  borderRadius: AppRadius.lg,
                ),
                SizedBox(height: AppSpacing.cardGap),
                AppSkeletonBox(
                  height: HomeStepsWeightRow.height,
                  borderRadius: AppRadius.lg,
                ),
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
    return const Row(
      children: [
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

class _HomeSectionSkeleton extends StatelessWidget {
  const _HomeSectionSkeleton({
    required this.titleWidth,
    this.itemCount = 1,
  });

  final double titleWidth;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final itemRadius = AppRadius.lg - AppSpacing.xs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.homeCardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppSkeletonBox(height: 22, width: titleWidth),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < itemCount; index += 1) ...[
            if (index > 0) const SizedBox(height: AppSpacing.md),
            AppSkeletonBox(
              height: HomePage._mealCardHeight,
              borderRadius: itemRadius,
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.records,
    required this.onMealTap,
    required this.onRefresh,
    required this.selectedDate,
    required this.onSelectedDateChanged,
    required this.onAddMealPressed,
    required this.onAddWorkoutPressed,
    required this.waterDays,
    required this.waterGoalMl,
    required this.onAddWaterPressed,
    required this.workoutEntries,
    required this.onWorkoutTap,
    required this.onWorkoutDelete,
    required this.playMascotCelebration,
    required this.idleMascotVideoAsset,
    required this.mascotCelebrationVideoAsset,
    required this.onMascotCelebrationCompleted,
    this.userProfile,
    this.goalUserProfile,
    this.onAvatarTap,
    this.onWeightUpdated,
  });

  final List<FoodMealRecord> records;
  final Future<void> Function(FoodMealRecord record) onMealTap;
  final Future<void> Function() onRefresh;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectedDateChanged;
  final VoidCallback onAddMealPressed;
  final VoidCallback onAddWorkoutPressed;
  final List<HomeWaterDay> waterDays;
  final int waterGoalMl;
  final VoidCallback onAddWaterPressed;
  final List<WorkoutDayEntry> workoutEntries;
  final ValueChanged<WorkoutDayEntry> onWorkoutTap;
  final ValueChanged<WorkoutDayEntry> onWorkoutDelete;
  final bool playMascotCelebration;
  final String idleMascotVideoAsset;
  final String mascotCelebrationVideoAsset;
  final VoidCallback onMascotCelebrationCompleted;
  final Map<String, dynamic>? userProfile;
  final Map<String, dynamic>? goalUserProfile;
  final VoidCallback? onAvatarTap;
  final ValueChanged<Map<String, dynamic>>? onWeightUpdated;

  @override
  Widget build(BuildContext context) {
    final bottomInset = homeShellFabBottomInset(context);
    final dayRecords = records
        .where((record) {
          if (record.status.trim().toLowerCase() == 'deleted') {
            return false;
          }
          final createdAt = record.createdAt;
          if (createdAt == null) {
            return true;
          }

          return isSameHomeDate(createdAt, selectedDate);
        })
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: AppAmbientPageBody(
        child: SafeArea(
          bottom: false,
          child: AppRefreshScrollView(
            onRefresh: onRefresh,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.xxl,
              AppSpacing.pageHorizontal,
              bottomInset + AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HomePage._headerSideInset,
                  ),
                  child: _Header(
                    userProfile: userProfile,
                    streakDays: readHomeProfileInt(userProfile, const [
                      'streakDays',
                      'streak_days',
                    ]),
                    onAvatarTap: onAvatarTap,
                  ),
                ),
                const SizedBox(height: HomePage._goalCardTopGap),
                HomeDailyGoalWithMascot(
                mascotAsset: HomePage._mealAsset,
                idleMascotVideoAsset: idleMascotVideoAsset,
                mascotVideoAsset: mascotCelebrationVideoAsset,
                playMascotVideo: playMascotCelebration,
                onMascotVideoCompleted: onMascotCelebrationCompleted,
                records: records,
                selectedDate: selectedDate,
                userProfile: goalUserProfile ?? userProfile,
              ),
              const SizedBox(height: AppSpacing.xl),
              HomeWeekDateSelector(
                selectedDate: selectedDate,
                onSelected: onSelectedDateChanged,
              ),
              const SizedBox(height: AppSpacing.xl),
              _HomeSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeader(title: 'Refeições'),
                    const SizedBox(height: AppSpacing.md),
                    _HomeSectionAddCard(
                      cardKey: const ValueKey('home-section-meals-add'),
                      label: 'Adicionar refeição',
                      onTap: onAddMealPressed,
                    ),
                    for (final (index, record) in dayRecords.indexed) ...[
                      const SizedBox(height: AppSpacing.md),
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
                        backgroundColor: AppColors.insetSurface,
                        onTap: () => onMealTap(record),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              _HomeSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeader(title: 'Treinos'),
                    const SizedBox(height: AppSpacing.md),
                    _HomeSectionAddCard(
                      cardKey: const ValueKey('home-section-workouts-add'),
                      label: 'Adicionar treino',
                      onTap: onAddWorkoutPressed,
                    ),
                    for (final (index, entry) in workoutEntries.indexed) ...[
                      const SizedBox(height: AppSpacing.md),
                      WorkoutDayExerciseCard(
                        key: ValueKey('home-workout-card-$index'),
                        entry: entry,
                        backgroundColor: AppColors.insetSurface,
                        onTap: () => onWorkoutTap(entry),
                        onDelete: () => onWorkoutDelete(entry),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              HomeWaterCard(
                days: waterDays,
                selectedDate: selectedDate,
                goalMl: waterGoalMl,
                onAdd: onAddWaterPressed,
              ),
              const SizedBox(height: AppSpacing.cardGap),
                HomeStepsWeightRow(onWeightUpdated: onWeightUpdated),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.userProfile, this.streakDays = 0, this.onAvatarTap});
  final Map<String, dynamic>? userProfile;
  final int streakDays;
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
    final avatarFrameId =
        userProfile?['equippedAvatarFrameId'] as String? ??
        userProfile?['equipped_avatar_frame_id'] as String?;
    final greeting = homeGreetingFor(DateTime.now());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: HomePage._homeAvatarSize,
          height: HomePage._homeAvatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: FramedAvatar(
                  size: HomePage._homeAvatarSize,
                  avatarUrl: avatarUrl,
                  frameId: avatarFrameId,
                  fallbackText: trimmedName,
                ),
              ),
              Positioned(
                top: HomePage._homeAvatarSize,
                child: _StreakChip(days: streakDays),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final label = days == 1 ? '1 dia de sequência' : '$days dias de sequência';

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 12,
            color: AppColors.socialMetricStreak,
          ),
          const SizedBox(width: 2),
          Text(
            '$days',
            key: const ValueKey('home-streak-days'),
            style: AppTextStyles.captionStrong.copyWith(
              color: AppColors.socialMetricStreak,
              fontSize: 10,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSectionCard extends StatelessWidget {
  const _HomeSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.homeCardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.homeSectionTitle.copyWith(
        color: AppColors.brand900Variant,
      ),
    );
  }
}

class _HomeSectionAddCard extends StatelessWidget {
  const _HomeSectionAddCard({
    required this.cardKey,
    required this.label,
    required this.onTap,
  });

  final Key cardKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg - AppSpacing.xs);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: cardKey,
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: HomePage._mealCardHeight,
          decoration: BoxDecoration(
            color: AppColors.insetSurface,
            borderRadius: radius,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                size: 22,
                color: AppColors.action500,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.homeAction.copyWith(
                  color: AppColors.action500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
