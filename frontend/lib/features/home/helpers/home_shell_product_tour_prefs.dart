import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/service/auth_service.dart';
import '../../missions/services/missions_service.dart';
import 'home_shell_product_tour_steps.dart';

class HomeShellProductTourPrefs {
  HomeShellProductTourPrefs({
    AuthService? authService,
    MissionsService? missionsService,
  }) : _authService = authService ?? AuthService(),
       _missionsService = missionsService ?? const MissionsService();

  final AuthService _authService;
  final MissionsService _missionsService;

  static const _stepKeyPrefix = 'home_product_tour_step_id';

  static bool isCompleted([Map<String, dynamic>? profile]) {
    final source = profile ?? AuthService.globalUser;
    if (source == null) {
      return false;
    }
    return _asBool(source['homeProductTourCompleted']) ||
        _asBool(source['home_product_tour_completed']);
  }

  static bool shouldShow([Map<String, dynamic>? profile]) {
    final source = profile ?? AuthService.globalUser;
    if (source == null) {
      return false;
    }
    return !isCompleted(source);
  }

  String? _progressStorageKey([Map<String, dynamic>? profile]) {
    final source = profile ?? AuthService.globalUser;
    final id = source?['id']?.toString().trim();
    if (id == null || id.isEmpty) {
      return null;
    }
    return '$_stepKeyPrefix:$id';
  }

  Future<void> saveProgress(HomeShellProductTourStepId stepId) async {
    final key = _progressStorageKey();
    if (key == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, stepId.name);
  }

  Future<int> resolveResumeIndex(
    List<HomeShellProductTourStep> steps, {
    Map<String, dynamic>? profile,
  }) async {
    if (steps.isEmpty) {
      return 0;
    }
    final key = _progressStorageKey(profile);
    if (key == null) {
      return 0;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(key)?.trim();
    if (saved == null || saved.isEmpty) {
      return 0;
    }
    final index = steps.indexWhere((step) => step.id.name == saved);
    if (index < 0) {
      return 0;
    }
    return index;
  }

  Future<void> clearProgress({Map<String, dynamic>? profile}) async {
    final key = _progressStorageKey(profile);
    if (key == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> markCompleted() async {
    await clearProgress();
    final current = AuthService.globalUser;
    if (current != null) {
      AuthService.globalUser = <String, dynamic>{
        ...current,
        'homeProductTourCompleted': true,
        'home_product_tour_completed': true,
      };
    }
    await _authService.updateProfile(<String, dynamic>{
      'homeProductTourCompleted': true,
    });
    try {
      final rewards = await _missionsService.claimProductTourRewards();
      final profile = rewards['profile'];
      if (profile is Map<String, dynamic> && AuthService.globalUser != null) {
        AuthService.globalUser = <String, dynamic>{
          ...AuthService.globalUser!,
          ...profile,
          'homeProductTourCompleted': true,
          'home_product_tour_completed': true,
        };
      }
      MissionsService.invalidateStoreCatalogCache();
    } catch (_) {}
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}
