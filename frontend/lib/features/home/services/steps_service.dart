import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/home_date_helpers.dart';
import '../helpers/home_steps_helpers.dart';
import '../models/home_steps_models.dart';

class StepsService {
  StepsService({
    Health? health,
    Future<SharedPreferences> Function()? prefsFactory,
  }) : _health = health ?? Health(),
       _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  static const _goalKey = 'home_steps_daily_goal';
  static const _bootBaselineKey = 'home_steps_boot_baseline';
  static const _bootBaselineDayKey = 'home_steps_boot_baseline_day';

  final Health _health;
  final Future<SharedPreferences> Function() _prefsFactory;

  bool _configured = false;
  StreamSubscription<StepCount>? _pedometerSub;
  int? _latestPedometerSteps;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  bool get _isMobile => _isAndroid || _isIOS;

  List<HealthDataType> get _types {
    if (_isIOS) {
      return const [
        HealthDataType.STEPS,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];
    }
    return const [
      HealthDataType.STEPS,
      HealthDataType.DISTANCE_DELTA,
      HealthDataType.ACTIVE_ENERGY_BURNED,
    ];
  }

  List<HealthDataAccess> get _permissions =>
      List<HealthDataAccess>.filled(_types.length, HealthDataAccess.READ);

  Future<HomeStepsOverview> fetchToday({
    num? weightKg,
    num? heightCm,
    bool requestPermission = false,
  }) async {
    final goal = await _readGoal();

    if (!_isMobile) {
      return HomeStepsOverview(
        goalSteps: goal,
        status: HomeStepsStatus.unsupported,
      );
    }

    try {
      await _ensureConfigured();

      if (_isAndroid) {
        final sdkStatus = await _health.getHealthConnectSdkStatus();
        if (sdkStatus != HealthConnectSdkStatus.sdkAvailable) {
          if (requestPermission) {
            await _health.installHealthConnect();
          }
          final pedometer = await _fetchFromPedometer(
            goal: goal,
            weightKg: weightKg,
            heightCm: heightCm,
            requestPermission: requestPermission,
          );
          if (pedometer != null) {
            return pedometer;
          }
          return HomeStepsOverview(
            goalSteps: goal,
            status: HomeStepsStatus.needsHealthConnect,
          );
        }
      }

      if (_isAndroid) {
        final activity = await Permission.activityRecognition.status;
        if (!activity.isGranted) {
          if (requestPermission) {
            final result = await Permission.activityRecognition.request();
            if (!result.isGranted) {
              return HomeStepsOverview(
                goalSteps: goal,
                status: HomeStepsStatus.needsPermission,
              );
            }
          } else {
            return HomeStepsOverview(
              goalSteps: goal,
              status: HomeStepsStatus.needsPermission,
            );
          }
        }
      }

      final hasPermissions = await _health.hasPermissions(
        _types,
        permissions: _permissions,
      );
      if (hasPermissions != true) {
        if (!requestPermission) {
          final pedometer = await _fetchFromPedometer(
            goal: goal,
            weightKg: weightKg,
            heightCm: heightCm,
            requestPermission: false,
          );
          if (pedometer != null) {
            return pedometer;
          }
          return HomeStepsOverview(
            goalSteps: goal,
            status: HomeStepsStatus.needsPermission,
          );
        }

        final granted = await _health.requestAuthorization(
          _types,
          permissions: _permissions,
        );
        if (!granted) {
          return HomeStepsOverview(
            goalSteps: goal,
            status: HomeStepsStatus.needsPermission,
          );
        }
      }

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(start, now) ?? 0;

      final distance = await _readDistanceKm(start, now);
      final calories = await _readActiveCalories(start, now);

      return HomeStepsOverview(
        steps: steps,
        goalSteps: goal,
        distanceKm:
            distance ??
            estimateStepsDistanceKm(steps: steps, heightCm: heightCm),
        caloriesKcal:
            calories ??
            estimateStepsCaloriesKcal(steps: steps, weightKg: weightKg),
        status: HomeStepsStatus.ready,
        sourceLabel: _isIOS ? 'Apple Saúde' : 'Health Connect',
      );
    } catch (_) {
      final pedometer = await _fetchFromPedometer(
        goal: goal,
        weightKg: weightKg,
        heightCm: heightCm,
        requestPermission: requestPermission,
      );
      if (pedometer != null) {
        return pedometer;
      }
      return HomeStepsOverview(
        goalSteps: goal,
        status: HomeStepsStatus.unavailable,
      );
    }
  }

  Future<HomeStepsOverview> requestAccessAndFetch({
    num? weightKg,
    num? heightCm,
  }) {
    return fetchToday(
      weightKg: weightKg,
      heightCm: heightCm,
      requestPermission: true,
    );
  }

  Future<void> dispose() async {
    await _pedometerSub?.cancel();
    _pedometerSub = null;
  }

  Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }
    await _health.configure();
    _configured = true;
  }

  Future<int> setDailyGoal(int goalSteps) async {
    final goal = clampDailyStepsGoal(goalSteps);
    final prefs = await _prefsFactory();
    await prefs.setInt(_goalKey, goal);
    return goal;
  }

  Future<int> _readGoal() async {
    final prefs = await _prefsFactory();
    return prefs.getInt(_goalKey) ?? HomeStepsOverview.defaultDailyStepsGoal;
  }

  Future<double?> _readDistanceKm(DateTime start, DateTime end) async {
    try {
      final types = _isIOS
          ? <HealthDataType>[HealthDataType.DISTANCE_WALKING_RUNNING]
          : <HealthDataType>[HealthDataType.DISTANCE_DELTA];
      final points = await _health.getHealthDataFromTypes(
        types: types,
        startTime: start,
        endTime: end,
      );
      var meters = 0.0;
      for (final point in points) {
        final value = point.value;
        if (value is NumericHealthValue) {
          meters += value.numericValue.toDouble();
        }
      }
      if (meters <= 0) {
        return null;
      }
      return meters / 1000;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _readActiveCalories(DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: end,
      );
      var kcal = 0.0;
      for (final point in points) {
        final value = point.value;
        if (value is NumericHealthValue) {
          kcal += value.numericValue.toDouble();
        }
      }
      if (kcal <= 0) {
        return null;
      }
      return kcal.round();
    } catch (_) {
      return null;
    }
  }

  Future<HomeStepsOverview?> _fetchFromPedometer({
    required int goal,
    num? weightKg,
    num? heightCm,
    required bool requestPermission,
  }) async {
    if (!_isMobile) {
      return null;
    }

    try {
      if (_isAndroid) {
        final activity = await Permission.activityRecognition.status;
        if (!activity.isGranted) {
          if (!requestPermission) {
            return null;
          }
          final result = await Permission.activityRecognition.request();
          if (!result.isGranted) {
            return null;
          }
        }
      }

      final stepsSinceBoot = await _readPedometerSteps();
      if (stepsSinceBoot == null) {
        return null;
      }

      final todaySteps = await _resolvePedometerTodaySteps(stepsSinceBoot);
      return HomeStepsOverview(
        steps: todaySteps,
        goalSteps: goal,
        distanceKm: estimateStepsDistanceKm(
          steps: todaySteps,
          heightCm: heightCm,
        ),
        caloriesKcal: estimateStepsCaloriesKcal(
          steps: todaySteps,
          weightKg: weightKg,
        ),
        status: HomeStepsStatus.ready,
        sourceLabel: 'Sensor do celular',
      );
    } catch (_) {
      return null;
    }
  }

  Future<int?> _readPedometerSteps() async {
    if (_latestPedometerSteps != null) {
      return _latestPedometerSteps;
    }

    final completer = Completer<int?>();
    StreamSubscription<StepCount>? subscription;
    Timer? timeout;

    try {
      subscription = Pedometer.stepCountStream.listen(
        (event) {
          _latestPedometerSteps = event.steps;
          if (!completer.isCompleted) {
            completer.complete(event.steps);
          }
        },
        onError: (_) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
        cancelOnError: true,
      );
      _pedometerSub ??= subscription;

      timeout = Timer(const Duration(seconds: 2), () {
        if (!completer.isCompleted) {
          completer.complete(_latestPedometerSteps);
        }
      });

      return await completer.future;
    } finally {
      timeout?.cancel();
      if (!identical(subscription, _pedometerSub)) {
        await subscription?.cancel();
      }
    }
  }

  Future<int> _resolvePedometerTodaySteps(int stepsSinceBoot) async {
    final prefs = await _prefsFactory();
    final todayKey = _dayKey(DateTime.now());
    final storedDay = prefs.getString(_bootBaselineDayKey);
    final storedBaseline = prefs.getInt(_bootBaselineKey);

    if (storedDay != todayKey || storedBaseline == null) {
      await prefs.setString(_bootBaselineDayKey, todayKey);
      await prefs.setInt(_bootBaselineKey, stepsSinceBoot);
      return 0;
    }

    final today = stepsSinceBoot - storedBaseline;
    return today < 0 ? stepsSinceBoot : today;
  }

  String _dayKey(DateTime date) {
    final day = normalizeHomeDate(date);
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final dayNumber = day.day.toString().padLeft(2, '0');
    return '$year-$month-$dayNumber';
  }
}
