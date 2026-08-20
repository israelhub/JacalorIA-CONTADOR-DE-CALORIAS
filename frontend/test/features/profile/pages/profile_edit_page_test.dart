import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/profile/pages/profile_edit_page.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('exibe privacidade de refeições ligada por padrão', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(const ProfileEditPage(initialProfile: {'name': 'Ana'})),
    );

    await tester.pumpAndSettle();

    expect(find.text('Editar dados pessoais'), findsOneWidget);
    expect(find.text('Mostrar refeições no perfil público'), findsOneWidget);
    expect(
      find.text('Quem visitar seu perfil verá as refeições do dia.'),
      findsNothing,
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('exibe privacidade de refeições desligada quando oculta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        const ProfileEditPage(initialProfile: {'hidePublicProfileMeals': true}),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(
      find.text('Suas refeições ficam visíveis só para você.'),
      findsNothing,
    );
  });
}
