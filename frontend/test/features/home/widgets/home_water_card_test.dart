import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/helpers/home_water_helpers.dart';
import 'package:jacaloria/features/home/widgets/home_add_water_sheet.dart';
import 'package:jacaloria/features/home/widgets/home_water_card.dart';

void main() {
  testWidgets('mostra consumo do dia e a meta', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeWaterCard(
            days: fillHomeWaterDays(
              selectedDate: DateTime(2026, 9, 27),
              millilitersByDate: const {'2026-09-27': 500, '2026-09-26': 1200},
            ),
            selectedDate: DateTime(2026, 9, 27),
            goalMl: 2000,
            onAdd: () {},
          ),
        ),
      ),
    );

    expect(find.text('Registre sua água!'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(find.text(' / 2 L'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-water-add')), findsOneWidget);
  });

  testWidgets('botao abre o modal manual de quantidade', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: HomeWaterCard(
                days: fillHomeWaterDays(
                  selectedDate: DateTime(2026, 9, 27),
                  millilitersByDate: const {},
                ),
                selectedDate: DateTime(2026, 9, 27),
                goalMl: 2000,
                onAdd: () {
                  showHomeAddWaterSheet(context);
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('home-water-add')));
    await tester.pumpAndSettle();

    expect(find.text('Registrar água'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-water-edit-field')), findsOneWidget);
    expect(find.text('200 ml'), findsNothing);
    expect(find.text('300 ml'), findsNothing);
    expect(find.text('500 ml'), findsNothing);
    expect(find.text('Salvar'), findsOneWidget);
  });
}
