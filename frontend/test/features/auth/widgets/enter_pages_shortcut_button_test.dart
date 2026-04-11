import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/widgets/enter_pages_shortcut_button.dart';
import 'package:jacaloria/features/home/pages/home_page.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('EnterPagesShortcutButton', () {
    testWidgets('exibe item Home no modal de atalhos', (tester) async {
      await tester.pumpWidget(_wrap(const EnterPagesShortcutButton()));

      await tester.tap(
        find.byKey(const ValueKey('enter-pages-shortcut-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('navega para HomePage ao tocar no item Home', (tester) async {
      await tester.pumpWidget(_wrap(const EnterPagesShortcutButton()));

      await tester.tap(
        find.byKey(const ValueKey('enter-pages-shortcut-button')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('page-shortcut-Home')));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
