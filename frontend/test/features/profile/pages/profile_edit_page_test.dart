import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/profile/pages/profile_edit_page.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpEditPage(
  WidgetTester tester, {
  Map<String, dynamic> profile = const {'name': 'Ana'},
}) async {
  tester.view.physicalSize = const Size(412, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(ProfileEditPage(initialProfile: profile)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('modo leitura mostra dados, editar e ações LGPD', (tester) async {
    await _pumpEditPage(tester);

    expect(find.text('Editar dados pessoais'), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Mostrar refeições no perfil público'), findsOneWidget);
    expect(find.text('Mostrar treinos no perfil público'), findsOneWidget);
    expect(find.text('Permitir analytics de uso'), findsOneWidget);
    expect(find.text('Política de Privacidade'), findsOneWidget);
    expect(find.text('Termos e Condições'), findsOneWidget);
    expect(find.text('Baixar meus dados'), findsOneWidget);
    expect(find.text('Excluir conta'), findsOneWidget);

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(3));
    expect(switches.every((item) => item.value), isTrue);
    expect(switches.every((item) => item.onChanged == null), isTrue);
  });

  testWidgets('botão editar libera campos e switches', (tester) async {
    await _pumpEditPage(
      tester,
      profile: const {'name': 'Ana', 'hidePublicProfileMeals': true},
    );

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Salvar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(3));
    expect(switches[0].value, isFalse);
    expect(switches[1].value, isTrue);
    expect(switches[2].value, isTrue);
    expect(switches.every((item) => item.onChanged != null), isTrue);
  });
}
