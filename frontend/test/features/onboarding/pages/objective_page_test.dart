import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/onboarding/pages/objective_page.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpObjectivePage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(const ObjectivePage()));
}

void main() {
  group('ObjectivePage - estrutura e seleção', () {
    testWidgets('renderiza título, opções e botão avançar', (tester) async {
      await _pumpObjectivePage(tester);

      expect(find.text('Objetivo'), findsOneWidget);
      expect(find.text('Emagrecer'), findsOneWidget);
      expect(find.text('Ganhar massa'), findsOneWidget);
      expect(find.text('Manter peso'), findsOneWidget);
      expect(find.text('Avançar'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('permite somente uma opção selecionada por vez', (
      tester,
    ) async {
      await _pumpObjectivePage(tester);

      await tester.tap(find.byKey(const ValueKey('objective-option-gain')));
      await tester.pumpAndSettle();

      final gainBox = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('objective-option-box-gain')),
      );
      final loseBox = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('objective-option-box-lose')),
      );
      final maintainBox = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('objective-option-box-maintain')),
      );

      final gainDecoration = gainBox.decoration as BoxDecoration;
      final loseDecoration = loseBox.decoration as BoxDecoration;
      final maintainDecoration = maintainBox.decoration as BoxDecoration;

      expect(gainDecoration.color, AppColors.brand900);
      expect(loseDecoration.color, AppColors.surface);
      expect(maintainDecoration.color, AppColors.surface);
    });
  });
}
