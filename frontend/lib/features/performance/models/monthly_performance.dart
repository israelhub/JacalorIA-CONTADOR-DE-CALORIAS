enum PerformanceDayStatus { goalAchieved, mealRegistered, noRecord }

class PerformanceCalendarDay {
  const PerformanceCalendarDay({
    required this.day,
    required this.status,
  });

  final int day;
  final PerformanceDayStatus status;

  factory PerformanceCalendarDay.fromJson(Map<String, dynamic> json) {
    return PerformanceCalendarDay(
      day: _asInt(json['day']),
      status: _statusFromJson(json['status'] as String? ?? ''),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static PerformanceDayStatus _statusFromJson(String value) {
    switch (value) {
      case 'goal_achieved':
        return PerformanceDayStatus.goalAchieved;
      case 'meal_registered':
        return PerformanceDayStatus.mealRegistered;
      default:
        return PerformanceDayStatus.noRecord;
    }
  }
}

class PerformanceMacroProgress {
  const PerformanceMacroProgress({
    required this.key,
    required this.label,
    required this.percent,
  });

  final String key;
  final String label;
  final int percent;

  factory PerformanceMacroProgress.fromJson(Map<String, dynamic> json) {
    return PerformanceMacroProgress(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      percent: _asInt(json['percent']),
    );
  }
}

class MonthlyPerformance {
  const MonthlyPerformance({
    required this.month,
    required this.streakDays,
    required this.streakMessage,
    required this.calendarYear,
    required this.calendarMonth,
    required this.daysInMonth,
    required this.calendarDays,
    required this.metGoalDays,
    required this.elapsedDays,
    required this.registeredDays,
    required this.consistencyPercent,
    required this.avgDailyCalories,
    required this.weightLostKg,
    required this.highlightTitle,
    required this.highlightDescription,
    required this.macroProgress,
  });

  final String month;
  final int streakDays;
  final String streakMessage;

  final int calendarYear;
  final int calendarMonth;
  final int daysInMonth;
  final List<PerformanceCalendarDay> calendarDays;

  final int metGoalDays;
  final int elapsedDays;
  final int registeredDays;
  final int consistencyPercent;
  final int avgDailyCalories;
  final double weightLostKg;

  final String highlightTitle;
  final String highlightDescription;
  final List<PerformanceMacroProgress> macroProgress;

  factory MonthlyPerformance.fromJson(Map<String, dynamic> json) {
    final calendar = (json['calendar'] as Map<String, dynamic>? ??
        const <String, dynamic>{});
    final report = (json['report'] as Map<String, dynamic>? ??
        const <String, dynamic>{});
    final highlight = (json['highlight'] as Map<String, dynamic>? ??
        const <String, dynamic>{});
    final days = (calendar['days'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(PerformanceCalendarDay.fromJson)
        .toList(growable: false);
    final macro = (highlight['macroProgress'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(PerformanceMacroProgress.fromJson)
        .toList(growable: false);

    return MonthlyPerformance(
      month: json['month'] as String? ?? '',
      streakDays: _asInt(json['streakDays']),
      streakMessage: json['streakMessage'] as String? ??
          'Continue registrando para não perder!',
      calendarYear: _asInt(calendar['year']),
      calendarMonth: _asInt(calendar['month']),
      daysInMonth: _asInt(calendar['daysInMonth']),
      calendarDays: days,
      metGoalDays: _asInt(report['metGoalDays']),
      elapsedDays: _asInt(report['elapsedDays']),
      registeredDays: _asInt(report['registeredDays']),
      consistencyPercent: _asInt(report['consistencyPercent']),
      avgDailyCalories: _asInt(report['avgDailyCalories']),
      weightLostKg: _asDouble(report['weightLostKg']),
      highlightTitle: highlight['title'] as String? ?? 'Destaque do mês',
      highlightDescription: highlight['description'] as String? ?? '',
      macroProgress: macro,
    );
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

double _asDouble(Object? value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  return 0;
}
