import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/performance/models/weight_history.dart';
import 'package:jacaloria/features/performance/widgets/weight_history_chart.dart';

void main() {
  testWidgets('mostra estado vazio sem pontos', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WeightHistoryChart(points: <WeightHistoryPoint>[]),
        ),
      ),
    );

    expect(find.text('Sem registros de peso no período.'), findsOneWidget);
    expect(find.byKey(const ValueKey('weight-history-chart-paint')), findsNothing);
  });

  testWidgets('pinta o grafico com largura visivel e resumo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: WeightHistoryChart(
              points: [
                WeightHistoryPoint(date: DateTime(2026, 7, 17), weight: 80),
                WeightHistoryPoint(date: DateTime(2026, 8, 5), weight: 82.5),
                WeightHistoryPoint(date: DateTime(2026, 7, 23), weight: 554),
              ],
              startDate: DateTime(2026, 6, 17),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sem registros de peso no período.'), findsNothing);
    expect(find.text('Dias de medição'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Mudança (kg)'), findsOneWidget);
    expect(find.text('2,50'), findsOneWidget);

    final size = tester.getSize(
      find.byKey(const ValueKey('weight-history-chart-paint')),
    );
    expect(size.width, greaterThan(100));
    expect(size.height, greaterThan(100));
  });
}
