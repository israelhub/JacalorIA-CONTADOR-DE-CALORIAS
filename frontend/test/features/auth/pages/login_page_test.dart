import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/pages/login_page.dart';

void main() {
  group('LoginPage', () {
    testWidgets('renderiza campos de email, senha e botão entrar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      expect(find.byType(Image), findsWidgets);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Continuar com Google'), findsOneWidget);
    });

    testWidgets('link cadastre-se é presente', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      expect(find.byKey(const ValueKey('signup-link')), findsOneWidget);
    });
  });
}
