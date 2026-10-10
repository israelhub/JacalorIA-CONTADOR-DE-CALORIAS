import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../auth/service/auth_service.dart';
import '../helpers/home_steps_helpers.dart';
import '../models/home_steps_models.dart';
import '../services/steps_service.dart';

class HomeStepsWeightController extends ChangeNotifier {
  HomeStepsWeightController({
    StepsService? stepsService,
    Map<String, dynamic>? initialProfile,
  }) : _stepsService = stepsService ?? StepsService() {
    final cached = initialProfile ?? AuthService.globalUser;
    if (cached != null && cached.isNotEmpty) {
      _userProfile = Map<String, dynamic>.from(cached);
    }
  }

  final StepsService _stepsService;

  HomeStepsOverview _steps = const HomeStepsOverview(
    status: HomeStepsStatus.unavailable,
  );
  Map<String, dynamic>? _userProfile;
  bool _isStepsLoading = true;
  Timer? _stepsRefreshTimer;

  HomeStepsOverview get steps => _steps;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isStepsLoading => _isStepsLoading;

  Future<void> ensureLoaded() async {
    if (_userProfile == null) {
      final cached = AuthService.globalUser;
      if (cached != null && cached.isNotEmpty) {
        _userProfile = Map<String, dynamic>.from(cached);
      }
    }
    await reloadSteps();
  }

  Future<void> syncProfile(Map<String, dynamic>? profile) async {
    if (profile == null || profile.isEmpty) {
      return;
    }
    _userProfile = Map<String, dynamic>.from(profile);
    notifyListeners();
    await reloadSteps(quietly: true);
  }

  Future<void> applyWeightUpdate(Map<String, dynamic> updatedProfile) async {
    _userProfile = <String, dynamic>{
      ...?_userProfile,
      ...updatedProfile,
      if (updatedProfile['weightUnit'] != null)
        'weight_unit': updatedProfile['weightUnit'],
    };
    notifyListeners();
    await reloadSteps(quietly: true);
  }

  Future<HomeStepsOverview> _fetchSteps({
    bool requestPermission = false,
  }) async {
    try {
      return await _stepsService.fetchToday(
        weightKg: readHomeProfileWeightKg(_userProfile),
        heightCm: readHomeProfileHeightCm(_userProfile),
        requestPermission: requestPermission,
      );
    } catch (_) {
      return const HomeStepsOverview(status: HomeStepsStatus.unavailable);
    }
  }

  Future<void> reloadSteps({
    bool requestPermission = false,
    bool quietly = false,
  }) async {
    if (!quietly) {
      _isStepsLoading = true;
      notifyListeners();
    }
    final overview = await _fetchSteps(requestPermission: requestPermission);
    _steps = overview;
    _isStepsLoading = false;
    notifyListeners();
    _scheduleStepsRefresh();
  }

  void _scheduleStepsRefresh() {
    _stepsRefreshTimer?.cancel();
    if (_steps.status != HomeStepsStatus.ready) {
      return;
    }
    _stepsRefreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(reloadSteps(quietly: true));
    });
  }

  Future<HomeStepsStatus> activateTracking() async {
    await reloadSteps(requestPermission: true);
    if (_steps.status == HomeStepsStatus.ready) {
      return _steps.status;
    }

    // Após o diálogo de permissão o status ainda pode vir stale no mesmo ciclo.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await reloadSteps(quietly: true);
    return _steps.status;
  }

  Future<int?> setGoal(int goalSteps) async {
    final goal = await _stepsService.setDailyGoal(goalSteps);
    _steps = _steps.copyWith(goalSteps: goal);
    notifyListeners();
    return goal;
  }

  @override
  void dispose() {
    _stepsRefreshTimer?.cancel();
    unawaited(_stepsService.dispose());
    super.dispose();
  }
}
