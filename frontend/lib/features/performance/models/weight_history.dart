class WeightHistoryPoint {
  const WeightHistoryPoint({
    required this.date,
    required this.weight,
  });

  final DateTime date;
  final double weight;

  factory WeightHistoryPoint.fromJson(Map<String, dynamic> json) {
    final dateText = json['date'] as String? ?? '';
    return WeightHistoryPoint(
      date: DateTime.tryParse(dateText) ?? DateTime.now(),
      weight: _asDouble(json['weight']),
    );
  }
}

class WeightHistoryRange {
  const WeightHistoryRange({
    required this.startDate,
    required this.endDate,
    required this.selectedPeriod,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String selectedPeriod;

  factory WeightHistoryRange.fromJson(Map<String, dynamic> json) {
    final startDateText = json['startDate'] as String? ?? '';
    final endDateText = json['endDate'] as String? ?? '';
    return WeightHistoryRange(
      startDate: DateTime.tryParse(startDateText) ?? DateTime.now(),
      endDate: DateTime.tryParse(endDateText) ?? DateTime.now(),
      selectedPeriod: json['selectedPeriod'] as String? ?? '30',
    );
  }
}

class WeightHistory {
  const WeightHistory({
    required this.range,
    required this.points,
  });

  final WeightHistoryRange range;
  final List<WeightHistoryPoint> points;

  factory WeightHistory.fromJson(Map<String, dynamic> json) {
    final rangeJson =
        json['range'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final pointsJson = json['points'] as List<dynamic>? ?? const <dynamic>[];

    return WeightHistory(
      range: WeightHistoryRange.fromJson(rangeJson),
      points: pointsJson
          .whereType<Map<String, dynamic>>()
          .map(WeightHistoryPoint.fromJson)
          .toList(growable: false),
    );
  }
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
