import 'package:shared_preferences/shared_preferences.dart';

import 'home_date_helpers.dart';
import 'home_greeting_helpers.dart';

/// Snapshot da meta calórica / objetivo válido para o dia civil local.
///
/// Na virada do dia, a meta do perfil é congelada e permanece estável até
/// o próximo dia — mesmo se o usuário alterar o perfil no meio do dia.
class HomeDailyGoalDaySnapshot {
  const HomeDailyGoalDaySnapshot({
    required this.dateKey,
    required this.dailyCalorieGoal,
    required this.objective,
  });

  final String dateKey;
  final int dailyCalorieGoal;
  final String objective;
}

String homeDailyGoalDayKey(DateTime date) {
  final normalized = normalizeHomeDate(date);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _storagePrefix(String userId) => 'home_daily_goal_day_$userId';

String resolveHomeDailyGoalUserId(Map<String, dynamic>? profile) {
  final raw =
      profile?['id'] ?? profile?['email'] ?? profile?['name'] ?? 'unknown-user';
  return raw.toString().trim();
}

Future<HomeDailyGoalDaySnapshot> resolveHomeDailyGoalDaySnapshot({
  required Map<String, dynamic>? profile,
  DateTime? now,
  SharedPreferences? preferences,
}) async {
  final todayKey = homeDailyGoalDayKey(now ?? DateTime.now());
  final userId = resolveHomeDailyGoalUserId(profile);
  final prefix = _storagePrefix(userId);
  final prefs = preferences ?? await SharedPreferences.getInstance();

  final liveGoal = readHomeProfileInt(profile, const [
    'daily_calorie_goal',
    'dailyCalorieGoal',
  ], fallback: 2000);
  final liveObjective =
      (profile?['objective'] as String?) ??
      (profile?['objective_type'] as String?) ??
      'maintainWeight';

  final storedDate = prefs.getString('${prefix}_date');
  if (storedDate != todayKey) {
    await prefs.setString('${prefix}_date', todayKey);
    await prefs.setInt('${prefix}_goal', liveGoal);
    await prefs.setString('${prefix}_objective', liveObjective);
    return HomeDailyGoalDaySnapshot(
      dateKey: todayKey,
      dailyCalorieGoal: liveGoal,
      objective: liveObjective,
    );
  }

  return HomeDailyGoalDaySnapshot(
    dateKey: todayKey,
    dailyCalorieGoal: prefs.getInt('${prefix}_goal') ?? liveGoal,
    objective: prefs.getString('${prefix}_objective') ?? liveObjective,
  );
}

/// Aplica o snapshot do dia apenas quando a data selecionada é o dia de hoje.
Map<String, dynamic>? applyHomeDailyGoalDaySnapshot({
  required Map<String, dynamic>? profile,
  required HomeDailyGoalDaySnapshot? snapshot,
  required DateTime selectedDate,
  DateTime? now,
}) {
  if (profile == null || snapshot == null) {
    return profile;
  }

  final today = normalizeHomeDate(now ?? DateTime.now());
  if (!isSameHomeDate(selectedDate, today)) {
    return profile;
  }

  return <String, dynamic>{
    ...profile,
    'dailyCalorieGoal': snapshot.dailyCalorieGoal,
    'daily_calorie_goal': snapshot.dailyCalorieGoal,
    'objective': snapshot.objective,
  };
}
