import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/onboarding/pages/objective_page.dart';
import 'package:jacaloria/features/onboarding/pages/personal_data_page.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpPersonalDataPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(const PersonalDataPage()));
}

void main() {
  group('PersonalDataPage - estrutura', () {
    testWidgets('renderiza título, campos e botão avançar', (tester) async {
      await _pumpPersonalDataPage(tester);

      expect(find.text('Dados pessoais'), findsOneWidget);
      expect(find.text('Data de nascimento'), findsOneWidget);
      expect(find.text('Peso'), findsOneWidget);
      expect(find.text('Altura'), findsOneWidget);
      expect(find.text('Sexo'), findsOneWidget);
      expect(find.text('Avançar'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('abre calendário ao tocar no campo de data', (tester) async {
      await _pumpPersonalDataPage(tester);

      await tester.tap(find.byKey(const ValueKey('personal-birthdate-field')));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarDatePicker), findsOneWidget);
    });

    testWidgets('sexo possui opções abrangentes e prefiro não informar', (
      tester,
    ) async {
      await _pumpPersonalDataPage(tester);

      await tester.tap(find.byKey(const ValueKey('personal-sex-field')));
      await tester.pumpAndSettle();

      expect(find.text('Masculino'), findsOneWidget);
      expect(find.text('Feminino'), findsOneWidget);
      expect(find.text('Demais'), findsOneWidget);
      expect(find.text('Prefiro não informar'), findsOneWidget);
    });

    testWidgets('navega para tela de objetivo ao tocar em avançar', (
      tester,
    ) async {
      await _pumpPersonalDataPage(tester);

      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();

      expect(find.byType(ObjectivePage), findsOneWidget);
    });

    testWidgets('botão avançar ocupa toda a largura disponível do formulário', (
      tester,
    ) async {
      await _pumpPersonalDataPage(tester);

      final buttonBox = tester.getSize(
        find.byKey(const ValueKey('personal-next-button-box')),
      );
      final viewWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final expectedWidth = viewWidth - (AppSpacing.xxl * 2);

      expect(buttonBox.width, expectedWidth);
    });
  });
}
