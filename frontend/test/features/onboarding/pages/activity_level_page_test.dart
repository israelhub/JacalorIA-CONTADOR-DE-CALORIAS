import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/onboarding/pages/activity_level_page.dart';

void main() {
  group('ActivityLevelPage', () {
    testWidgets('renderiza título, opções e botão finalizar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ActivityLevelPage()));

      expect(find.text('Nível de\natividade física'), findsOneWidget);
      expect(find.text('Sedentário (não pratico exercícios)'), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.text('Finalizar'), findsOneWidget);
    });

    testWidgets('permite somente uma opção selecionada por vez', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ActivityLevelPage()));

      // Verifica que há opções disponíveis
      expect(
        find.byKey(const ValueKey('activity-option-sedentary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('activity-option-lightly')),
        findsOneWidget,
      );

      // Clica em "Levemente ativo"
      await tester.tap(find.byKey(const ValueKey('activity-option-lightly')));
      await tester.pumpAndSettle();

      // Verifica que eventos foram disparados
      expect(
        find.text('Levemente ativo (1-2 dias por semana)'),
        findsOneWidget,
      );

      // Clica em "Sedentário" novamente
      await tester.tap(find.byKey(const ValueKey('activity-option-sedentary')));
      await tester.pumpAndSettle();

      // Verifica que a seleção mudou
      expect(find.text('Sedentário (não pratico exercícios)'), findsOneWidget);
    });
  });
}
