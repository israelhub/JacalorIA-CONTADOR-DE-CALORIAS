import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/profile/widgets/profile_privacy_card.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('mostra refeições públicas como ligadas', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ProfilePrivacyCard(
          mealsVisible: true,
          busy: false,
          onMealsVisibleChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Mostrar refeições no perfil público'), findsOneWidget);
    expect(
      find.text('Quem visitar seu perfil verá as refeições do dia.'),
      findsNothing,
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('mostra refeições privadas como desligadas', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ProfilePrivacyCard(
          mealsVisible: false,
          busy: false,
          onMealsVisibleChanged: (_) {},
        ),
      ),
    );

    expect(
      find.text('Suas refeições ficam visíveis só para você.'),
      findsNothing,
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });
}
