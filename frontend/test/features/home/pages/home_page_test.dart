import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/pages/home_page.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpHomePage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(const HomePage()));
}

void main() {
  group('HomePage', () {
    testWidgets('renderiza estrutura base da tela sem erro', (tester) async {
      await _pumpHomePage(tester);
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-daily-goal-card')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('home-mascot-overlay')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-bottom-camera-button')),
        findsOneWidget,
      );
    });

    testWidgets('renderiza estado inicial da secao de refeicoes', (
      tester,
    ) async {
      await _pumpHomePage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Refeicoes de hoje'), findsOneWidget);
      expect(find.text('Adicionar refeição'), findsOneWidget);
    });

    testWidgets('progress indicators sao renderizados com valores validos', (
      tester,
    ) async {
      await _pumpHomePage(tester);
      await tester.pumpAndSettle();

      final circularProgress = tester.widgetList<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(circularProgress, isNotEmpty);

      for (final widget in circularProgress) {
        expect(widget.value, isNotNull);
        expect(widget.value!, greaterThanOrEqualTo(0));
        expect(widget.value!, lessThanOrEqualTo(1));
      }

      final linearProgress = tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(linearProgress.length, 3);

      for (final widget in linearProgress) {
        expect(widget.value, isNotNull);
        expect(widget.value!, greaterThanOrEqualTo(0));
        expect(widget.value!, lessThanOrEqualTo(1));
      }
    });
  });
}
