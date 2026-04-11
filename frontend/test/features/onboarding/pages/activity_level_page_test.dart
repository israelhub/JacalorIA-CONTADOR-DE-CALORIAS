import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/pages/home_page.dart';
import 'package:jacaloria/features/onboarding/pages/activity_level_page.dart';
import 'package:jacaloria/features/onboarding/widgets/onboarding_step_header.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpActivityLevelPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(const ActivityLevelPage()));
}

void main() {
  group('ActivityLevelPage', () {
    testWidgets('renderiza título, opções e botão finalizar', (
      WidgetTester tester,
    ) async {
      await _pumpActivityLevelPage(tester);

      expect(find.text('Qual seu nível de atividade física?'), findsOneWidget);
      expect(find.text('Sedentário (não pratico exercícios)'), findsOneWidget);
      expect(find.byType(OnboardingStepHeader), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.text('Finalizar'), findsOneWidget);
    });

    testWidgets('permite somente uma opção selecionada por vez', (
      WidgetTester tester,
    ) async {
      await _pumpActivityLevelPage(tester);

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

    testWidgets('botão finalizar ocupa toda a largura disponível da página', (
      WidgetTester tester,
    ) async {
      await _pumpActivityLevelPage(tester);

      final buttonBox = tester.getSize(
        find.byKey(const ValueKey('activity-finish-button-box')),
      );
      final viewWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final expectedWidth = viewWidth - (AppSpacing.xxl * 2);

      expect(buttonBox.width, expectedWidth);
    });

    testWidgets('opções ocupam a largura do container e não há scroll', (
      WidgetTester tester,
    ) async {
      await _pumpActivityLevelPage(tester);

      final sedentaryRect = tester.getRect(
        find.byKey(const ValueKey('activity-option-box-sedentary')),
      );
      final extremeRect = tester.getRect(
        find.byKey(const ValueKey('activity-option-box-extreme')),
      );
      final buttonRect = tester.getRect(
        find.byKey(const ValueKey('activity-finish-button-box')),
      );

      expect(find.byType(Scrollable), findsNothing);
      expect(sedentaryRect.width, buttonRect.width);
      expect(buttonRect.top - extremeRect.bottom, AppSpacing.huge);
    });

    testWidgets('navega para HomePage ao tocar em Finalizar', (
      WidgetTester tester,
    ) async {
      await _pumpActivityLevelPage(tester);

      await tester.tap(find.text('Finalizar'));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
