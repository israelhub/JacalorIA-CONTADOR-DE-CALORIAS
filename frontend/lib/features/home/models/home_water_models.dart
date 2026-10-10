import '../helpers/home_date_helpers.dart';
import '../helpers/home_water_helpers.dart';

class WaterDayEntry {
  const WaterDayEntry({
    this.id,
    required this.recordedAt,
    required this.milliliters,
  });

  final String? id;
  final DateTime recordedAt;
  final int milliliters;

  factory WaterDayEntry.fromJson(Map<String, dynamic> json) {
    final rawDate = json['recordedAt'] ?? json['recorded_at'];
    return WaterDayEntry(
      id: json['id'] as String?,
      recordedAt: rawDate is String
          ? DateTime.tryParse(rawDate) ?? DateTime.now()
          : DateTime.now(),
      milliliters: _asInt(json['milliliters']),
    );
  }
}

class WaterOverview {
  const WaterOverview({
    this.goalMl = defaultDailyWaterGoalMl,
    this.days = const <WaterDayEntry>[],
  });

  final int goalMl;
  final List<WaterDayEntry> days;

  Map<String, int> get millilitersByDate {
    return <String, int>{
      for (final day in days)
        homeDateQuery(normalizeHomeDate(day.recordedAt)): day.milliliters,
    };
  }

  factory WaterOverview.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    return WaterOverview(
      goalMl: _asInt(
        json['goalMl'] ?? json['goal_ml'],
        fallback: defaultDailyWaterGoalMl,
      ),
      days: rawDays is List
          ? rawDays
                .whereType<Map<String, dynamic>>()
                .map(WaterDayEntry.fromJson)
                .toList(growable: false)
          : const <WaterDayEntry>[],
    );
  }

  WaterOverview copyWithGoal(int goalMl) {
    return WaterOverview(goalMl: goalMl, days: days);
  }

  WaterOverview replacingDay(WaterDayEntry entry) {
    final key = homeDateQuery(normalizeHomeDate(entry.recordedAt));
    final next = [
      for (final day in days)
        if (homeDateQuery(normalizeHomeDate(day.recordedAt)) != key) day,
      entry,
    ];
    return WaterOverview(goalMl: goalMl, days: next);
  }
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}
