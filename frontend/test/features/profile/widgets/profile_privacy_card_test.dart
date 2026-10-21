import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/profile/widgets/profile_privacy_card.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('mostra refeições, treinos e analytics ligados', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ProfilePrivacyCard(
          mealsVisible: true,
          workoutsVisible: true,
          analyticsEnabled: true,
          busy: false,
          onMealsVisibleChanged: (_) {},
          onWorkoutsVisibleChanged: (_) {},
          onAnalyticsEnabledChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Mostrar refeições no perfil público'), findsOneWidget);
    expect(find.text('Mostrar treinos no perfil público'), findsOneWidget);
    expect(find.text('Permitir analytics de uso'), findsOneWidget);
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(3));
    expect(switches.every((item) => item.value), isTrue);
  });

  testWidgets('mostra refeições, treinos e analytics desligados', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ProfilePrivacyCard(
          mealsVisible: false,
          workoutsVisible: false,
          analyticsEnabled: false,
          busy: false,
          onMealsVisibleChanged: (_) {},
          onWorkoutsVisibleChanged: (_) {},
          onAnalyticsEnabledChanged: (_) {},
        ),
      ),
    );

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(3));
    expect(switches.every((item) => !item.value), isTrue);
  });
}
