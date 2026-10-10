import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/profile/widgets/profile_privacy_card.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('mostra refeições e treinos públicos como ligados', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ProfilePrivacyCard(
          mealsVisible: true,
          workoutsVisible: true,
          busy: false,
          onMealsVisibleChanged: (_) {},
          onWorkoutsVisibleChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Mostrar refeições no perfil público'), findsOneWidget);
    expect(find.text('Mostrar treinos no perfil público'), findsOneWidget);
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(2));
    expect(switches.every((item) => item.value), isTrue);
  });

  testWidgets('mostra refeições e treinos privados como desligados', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ProfilePrivacyCard(
          mealsVisible: false,
          workoutsVisible: false,
          busy: false,
          onMealsVisibleChanged: (_) {},
          onWorkoutsVisibleChanged: (_) {},
        ),
      ),
    );

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(2));
    expect(switches.every((item) => !item.value), isTrue);
  });
}
