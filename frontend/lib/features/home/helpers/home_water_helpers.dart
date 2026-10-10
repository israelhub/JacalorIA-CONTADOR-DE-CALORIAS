import 'home_date_helpers.dart';

const defaultDailyWaterGoalMl = 2000;
const waterMlPerKg = 35;
const minDailyWaterGoalMl = 1500;
const maxDailyWaterGoalMl = 4000;
const homeWaterChartDayCount = 7;
const homeWaterQuickAmountsMl = <int>[200, 300, 500];

int resolveDailyWaterGoalMl({num? weightKg}) {
  if (weightKg == null || weightKg <= 0) {
    return defaultDailyWaterGoalMl;
  }
  return (weightKg * waterMlPerKg).round().clamp(
    minDailyWaterGoalMl,
    maxDailyWaterGoalMl,
  );
}

String formatWaterVolume(int milliliters) {
  if (milliliters >= 1000) {
    final liters = milliliters / 1000;
    final text = milliliters % 1000 == 0
        ? liters.toStringAsFixed(0)
        : liters.toStringAsFixed(1).replaceAll('.', ',');
    return '$text L';
  }
  return '$milliliters ml';
}

String homeDateQuery(DateTime date) {
  final day = normalizeHomeDate(date);
  final year = day.year.toString().padLeft(4, '0');
  final month = day.month.toString().padLeft(2, '0');
  final dayNumber = day.day.toString().padLeft(2, '0');
  return '$year-$month-$dayNumber';
}

List<DateTime> homeWaterChartDays(
  DateTime selected, {
  int count = homeWaterChartDayCount,
}) {
  final end = normalizeHomeDate(selected);
  return [
    for (var i = count - 1; i >= 0; i--)
      DateTime(end.year, end.month, end.day - i),
  ];
}

class HomeWaterDay {
  const HomeWaterDay({required this.date, required this.milliliters});

  final DateTime date;
  final int milliliters;
}

List<HomeWaterDay> fillHomeWaterDays({
  required DateTime selectedDate,
  required Map<String, int> millilitersByDate,
  int count = homeWaterChartDayCount,
}) {
  return [
    for (final date in homeWaterChartDays(selectedDate, count: count))
      HomeWaterDay(
        date: date,
        milliliters: millilitersByDate[homeDateQuery(date)] ?? 0,
      ),
  ];
}
