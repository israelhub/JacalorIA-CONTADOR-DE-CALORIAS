import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/performance/helpers/weight_history_chart_helpers.dart';
import 'package:jacaloria/features/performance/models/weight_history.dart';

void main() {
  test('fromJson le pontos mesmo quando o mapa vem sem tipo', () {
    final decoded = jsonDecode(
      '{"range":{"startDate":"2026-07-17","endDate":"2026-08-15","selectedPeriod":"30"},'
      '"points":[{"date":"2026-08-05T09:45:18.042Z","weight":82.5},'
      '{"date":"2026-08-01T17:51:41.052Z","weight":82}]}',
    );

    final history = WeightHistory.fromJson(
      Map<String, dynamic>.from(decoded as Map),
    );

    expect(history.points, hasLength(2));
    expect(history.points.first.weight, 82.5);
    expect(history.points.last.weight, 82);
  });

  test('ignora peso implausivel na escala do grafico', () {
    final points = selectWeightChartPoints([
      WeightHistoryPoint(date: DateTime(2026, 7, 22), weight: 79.4),
      WeightHistoryPoint(date: DateTime(2026, 7, 23), weight: 554),
      WeightHistoryPoint(date: DateTime(2026, 8, 5), weight: 82.5),
    ]);

    expect(points.map((point) => point.weight), [79.4, 82.5]);

    final scale = computeWeightChartScale(points.map((point) => point.weight));
    expect(scale.minWeight, lessThanOrEqualTo(79.4));
    expect(scale.maxWeight, greaterThanOrEqualTo(82.5));
    expect(scale.range, greaterThan(3.1));
    expect(scale.ticks.length, greaterThanOrEqualTo(2));
    expect(scale.ticks.first, scale.minWeight);
    expect(scale.ticks.last, scale.maxWeight);
  });

  test('usa so o peso mais recente de cada dia', () {
    final daily = latestWeightPerDay([
      WeightHistoryPoint(date: DateTime(2026, 7, 24, 17, 18), weight: 91),
      WeightHistoryPoint(date: DateTime(2026, 7, 24, 17, 27), weight: 92),
      WeightHistoryPoint(date: DateTime(2026, 7, 25, 8, 0), weight: 90.5),
    ]);

    expect(daily, hasLength(2));
    expect(daily.first.weight, 92);
    expect(daily.first.date, DateTime(2026, 7, 24, 17, 27));
    expect(daily.last.weight, 90.5);
  });

  test('conta dias de medicao unicos e mudanca de peso', () {
    final points = latestWeightPerDay([
      WeightHistoryPoint(date: DateTime(2026, 8, 8, 8), weight: 83.25),
      WeightHistoryPoint(date: DateTime(2026, 8, 8, 20), weight: 83.1),
      WeightHistoryPoint(date: DateTime(2026, 8, 12), weight: 81.9),
      WeightHistoryPoint(date: DateTime(2026, 8, 14), weight: 82.8),
    ]);

    expect(countMeasurementDays(points), 3);
    expect(points.first.weight, 83.1);
    expect(weightChangeKg(points), closeTo(-0.3, 0.0001));
  });

  test('eixo X comeca no primeiro registro quando o periodo tem dias vazios', () {
    final first = DateTime(2026, 8, 8);
    final last = DateTime(2026, 8, 19);

    expect(
      resolveWeightChartAxisStart(
        firstRecordDay: first,
        lastRecordDay: last,
        periodStart: DateTime(2026, 7, 21),
      ),
      first,
    );

    expect(
      resolveWeightChartAxisStart(
        firstRecordDay: DateTime(2026, 7, 21),
        lastRecordDay: last,
        periodStart: DateTime(2026, 7, 21),
      ),
      DateTime(2026, 7, 21),
    );

    expect(
      resolveWeightChartAxisStart(
        firstRecordDay: DateTime(2026, 7, 10),
        lastRecordDay: last,
        periodStart: DateTime(2026, 7, 21),
      ),
      DateTime(2026, 7, 21),
    );
  });

  test('monta eixo de datas do periodo sem empilhar labels', () {
    final week = buildWeightChartDateAxis(
      startDate: DateTime(2026, 8, 8),
      endDate: DateTime(2026, 8, 14),
    );
    expect(week.first, DateTime(2026, 8, 8));
    expect(week.last, DateTime(2026, 8, 14));
    expect(week.length, lessThanOrEqualTo(5));

    final month = buildWeightChartDateAxis(
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31),
      maxLabels: 5,
    );
    expect(month.length, lessThanOrEqualTo(5));
    expect(month.first, DateTime(2026, 7, 1));
    expect(month.last, DateTime(2026, 7, 31));

    final year = buildWeightChartDateAxis(
      startDate: DateTime(2025, 8, 19),
      endDate: DateTime(2026, 8, 19),
      maxLabels: 5,
    );
    expect(year.length, 5);
    expect(year.first, DateTime(2025, 8, 19));
    expect(year.last, DateTime(2026, 8, 19));
  });
}
