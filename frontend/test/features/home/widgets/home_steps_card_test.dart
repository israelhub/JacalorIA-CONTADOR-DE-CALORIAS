import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/models/home_steps_models.dart';
import 'package:jacaloria/features/home/widgets/home_steps_card.dart';

void main() {
  testWidgets('mostra passos restantes, kcal e distancia', (tester) async {
    var editedGoal = false;
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
            onEditGoal: () => editedGoal = true,
          ),
        ),
      ),
    );

    expect(find.text('Passos'), findsOneWidget);
    expect(find.text('👣'), findsOneWidget);
    expect(find.text('5.480'), findsOneWidget);
    expect(find.text('restantes'), findsOneWidget);
    expect(find.text('148 kcal'), findsOneWidget);
    expect(find.text('3,20 km'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-steps-activate')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-steps-goal-edit')));
    expect(editedGoal, isTrue);
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
