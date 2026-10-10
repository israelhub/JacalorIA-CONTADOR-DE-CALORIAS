import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/models/home_steps_models.dart';
import 'package:jacaloria/features/home/widgets/home_steps_card.dart';

void main() {
  testWidgets('mostra passos restantes, kcal e distancia', (tester) async {
    var openedDetails = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeStepsCard(
            overview: const HomeStepsOverview(
              steps: 4520,
              goalSteps: 10000,
              distanceKm: 3.2,
              caloriesKcal: 148,
              status: HomeStepsStatus.ready,
              sourceLabel: 'Health Connect',
            ),
            onOpenDetails: () => openedDetails = true,
          ),
        ),
      ),
    );

    expect(find.text('Passos'), findsOneWidget);
    expect(find.text('5.480'), findsOneWidget);
    expect(find.text('passos restantes'), findsOneWidget);
    expect(find.text('148 kcal'), findsNothing);
    expect(find.text('3,20 km'), findsNothing);
    expect(find.byKey(const ValueKey('home-steps-activate')), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-steps-open')));
    expect(openedDetails, isTrue);
  });

  testWidgets('expandido mostra distancia e calorias entre ratio e progresso', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeStepsCard(
            overview: const HomeStepsOverview(
              steps: 4520,
              goalSteps: 10000,
              distanceKm: 3.2,
              caloriesKcal: 148,
              status: HomeStepsStatus.ready,
              sourceLabel: 'Health Connect',
            ),
            expanded: true,
          ),
        ),
      ),
    );

    expect(find.text('4.520'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-steps-distance-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-steps-calories-card')), findsOneWidget);
    expect(find.text('Distância'), findsOneWidget);
    expect(find.text('Calorias'), findsOneWidget);
  });

  testWidgets('mostra botao para ativar quando falta permissao', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeStepsCard(
            overview: const HomeStepsOverview(
              status: HomeStepsStatus.needsPermission,
            ),
            onActivate: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Ativar'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-steps-activate')));
    expect(tapped, isTrue);
  });
}
