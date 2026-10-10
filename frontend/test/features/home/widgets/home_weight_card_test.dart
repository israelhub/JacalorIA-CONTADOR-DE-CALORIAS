import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/widgets/home_weight_card.dart';

void main() {
  testWidgets('mostra peso atual e botao de adicionar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeWeightCard(
            userProfile: const {'weight': 72.5, 'weightUnit': 'kg'},
            onWeightUpdated: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Peso'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-weight-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-weight-card-value')), findsOneWidget);
    expect(find.text('72,5'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-weight-add')), findsOneWidget);
  });

  testWidgets('abre sheet ao tocar em adicionar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeWeightCard(
            userProfile: const {'weight': 70, 'weightUnit': 'kg'},
            onWeightUpdated: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('home-weight-add')));
    await tester.pumpAndSettle();

    expect(find.text('Atualizar peso'), findsOneWidget);
  });
}
