import 'dart:math' as math;

import '../models/weight_history.dart';

const plausibleWeightMinKg = 20.0;
const plausibleWeightMaxKg = 400.0;

List<WeightHistoryPoint> selectWeightChartPoints(
  List<WeightHistoryPoint> points,
) {
  final plausible = points
      .where(
        (point) =>
            point.weight >= plausibleWeightMinKg &&
            point.weight <= plausibleWeightMaxKg,
      )
      .toList(growable: false);

  if (plausible.isNotEmpty) {
    return plausible;
  }

  return List<WeightHistoryPoint>.from(points);
}

class WeightChartScale {
  const WeightChartScale({
    required this.minWeight,
    required this.maxWeight,
    required this.range,
    required this.ticks,
  });

  final double minWeight;
  final double maxWeight;
  final double range;
  final List<double> ticks;
}

WeightChartScale computeWeightChartScale(Iterable<double> weights) {
  final values = weights.toList(growable: false);
  if (values.isEmpty) {
    return const WeightChartScale(
      minWeight: 0,
      maxWeight: 1,
      range: 1,
      ticks: <double>[0, 0.5, 1],
    );
  }

  final dataMin = values.reduce(math.min);
  final dataMax = values.reduce(math.max);
  final span = (dataMax - dataMin).abs();
  final paddedSpan = span < 0.1 ? 1.0 : span * 1.35;
  final mid = (dataMin + dataMax) / 2;
  final minWeight = mid - (paddedSpan / 2);
  final maxWeight = mid + (paddedSpan / 2);
  final ticks = computeWeightChartTicks(minWeight, maxWeight);

  return WeightChartScale(
    minWeight: ticks.first,
    maxWeight: ticks.last,
    range: ticks.last - ticks.first,
    ticks: ticks,
  );
}

List<double> computeWeightChartTicks(double minWeight, double maxWeight) {
  const preferredCount = 6;
  final span = (maxWeight - minWeight).abs();
  if (span < 0.0001) {
    final center = minWeight;
    return <double>[center - 1, center - 0.5, center, center + 0.5, center + 1];
  }

  final rawStep = span / (preferredCount - 1);
  final step = _niceStep(rawStep);
  final niceMin = (minWeight / step).floor() * step;
  final niceMax = (maxWeight / step).ceil() * step;

  final ticks = <double>[];
  for (var value = niceMin; value <= niceMax + (step * 0.5); value += step) {
    ticks.add(double.parse(value.toStringAsFixed(4)));
  }

  if (ticks.length < 2) {
    return <double>[minWeight, maxWeight];
  }

  return ticks;
}

double _niceStep(double rawStep) {
  if (rawStep <= 0) {
    return 0.5;
  }

  final exponent = (math.log(rawStep) / math.ln10).floor();
  final magnitude = math.pow(10, exponent).toDouble();
  final fraction = rawStep / magnitude;

  final niceFraction = switch (fraction) {
    <= 1 => 1.0,
    <= 2 => 2.0,
    <= 2.5 => 2.5,
    <= 5 => 5.0,
    _ => 10.0,
  };

  return niceFraction * magnitude;
}

int countMeasurementDays(List<WeightHistoryPoint> points) {
  final days = <DateTime>{};
  for (final point in points) {
    days.add(DateTime(point.date.year, point.date.month, point.date.day));
  }
  return days.length;
}

double? weightChangeKg(List<WeightHistoryPoint> points) {
  if (points.length < 2) {
    return null;
  }

  final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));
  return sorted.last.weight - sorted.first.weight;
}

DateTime normalizeWeightChartDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime resolveWeightChartAxisStart({
  required DateTime firstRecordDay,
  required DateTime lastRecordDay,
  DateTime? periodStart,
}) {
  final first = normalizeWeightChartDay(firstRecordDay);
  final last = normalizeWeightChartDay(lastRecordDay);
  if (periodStart == null) {
    return first;
  }

  final start = normalizeWeightChartDay(periodStart);
  if (start.isAfter(last) || start.isBefore(first)) {
    return first;
  }

  return start;
}

List<DateTime> buildWeightChartDateAxis({
  required DateTime startDate,
  required DateTime endDate,
  int maxLabels = 5,
}) {
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);
  if (!end.isAfter(start)) {
    return <DateTime>[start];
  }

  final dayCount = end.difference(start).inDays + 1;
  final count = math.min(math.max(maxLabels, 2), dayCount);
  if (count <= 2) {
    return <DateTime>[start, end];
  }

  final seen = <int>{};
  final dates = <DateTime>[];
  for (var i = 0; i < count; i++) {
    final offset = ((dayCount - 1) * i / (count - 1)).round();
    if (seen.add(offset)) {
      dates.add(start.add(Duration(days: offset)));
    }
  }
  return dates;
}

List<WeightHistoryPoint> latestWeightPerDay(List<WeightHistoryPoint> points) {
  final latestByDay = <DateTime, WeightHistoryPoint>{};
  for (final point in points) {
    final key = DateTime(point.date.year, point.date.month, point.date.day);
    final existing = latestByDay[key];
    if (existing == null || point.date.isAfter(existing.date)) {
      latestByDay[key] = point;
    }
  }

  final daily = latestByDay.values.toList(growable: false)
    ..sort((a, b) => a.date.compareTo(b.date));
  return daily;
}
