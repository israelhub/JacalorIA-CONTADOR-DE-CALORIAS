import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/controllers/auth_controller.dart';
import 'package:jacaloria/features/auth/pages/login_page.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._success, this._errorMessage);

  final bool _success;
  final String? _errorMessage;

  @override
  Future<bool> signIn({required String email, required String password}) async {
    error = _errorMessage;
    notifyListeners();
    return _success;
  }
}

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

    testWidgets('exibe mensagem quando login falha', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            authController: _FakeAuthController(false, 'Credenciais inválidas'),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextField).at(0),
        'teste@jacaloria.app',
      );
      await tester.enterText(find.byType(TextField).at(1), 'senha123');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Credenciais inválidas'), findsOneWidget);
    });
  });
}
