import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/pages/email_confirmation_page.dart';
import 'package:jacaloria/features/auth/pages/login_page.dart';
import 'package:jacaloria/features/auth/pages/sign_up_page.dart';
import 'package:jacaloria/shared/widgets/app_button.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('SignUpPage - estrutura', () {
    testWidgets('renderiza logo, campos e ações principais', (tester) async {
      await tester.pumpWidget(_wrap(const SignUpPage()));

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Confirmar senha'), findsOneWidget);

      expect(find.text('Ex.: Maria Silva'), findsNothing);
      expect(find.text('Ex.: maria@email.com'), findsNothing);
      expect(find.text('Ex.: sua senha'), findsNothing);
      expect(find.text('Ex.: confirme a senha'), findsNothing);

      expect(find.byType(TextField), findsNWidgets(4));
      expect(find.text('Criar conta'), findsOneWidget);
      expect(find.text('Continuar com Google'), findsOneWidget);
      expect(find.text('Já tem uma conta?'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('exibe botões com variantes corretas', (tester) async {
      await tester.pumpWidget(_wrap(const SignUpPage()));

      final buttons = tester.widgetList<AppButton>(find.byType(AppButton)).toList();

      expect(buttons, hasLength(2));
      expect(buttons[0].variant, AppButtonVariant.primary);
      expect(buttons[1].variant, AppButtonVariant.google);
    });

    testWidgets('campos usam floating label', (tester) async {
      await tester.pumpWidget(_wrap(const SignUpPage()));

      final decorations = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.decoration)
          .whereType<InputDecoration>()
          .toList();

      expect(decorations, hasLength(4));
      expect(
        decorations.map((d) => d.labelText).toList(),
        ['Nome', 'E-mail', 'Senha', 'Confirmar senha'],
      );
      for (final decoration in decorations) {
        expect(decoration.floatingLabelBehavior, FloatingLabelBehavior.auto);
      }
    });

    testWidgets('não navega quando formulário está inválido', (tester) async {
      await tester.pumpWidget(_wrap(const SignUpPage()));

      await tester.ensureVisible(find.text('Criar conta'));
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpPage), findsOneWidget);
      expect(find.byType(EmailConfirmationPage), findsNothing);
    });

    testWidgets('aceita formulário válido e tenta criar conta', (tester) async {
      await tester.pumpWidget(_wrap(const SignUpPage()));

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Jon');
      await tester.enterText(fields.at(1), 'jon@email.com');
      await tester.enterText(fields.at(2), 'Senha@123');
      await tester.enterText(fields.at(3), 'Senha@123');

      await tester.ensureVisible(find.text('Criar conta'));
      await tester.tap(find.text('Criar conta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SignUpPage), findsOneWidget);
      expect(find.text('Informe seu nome'), findsNothing);
      expect(find.text('Informe um e-mail válido'), findsNothing);
      expect(find.text('As senhas não conferem'), findsNothing);
    });

    testWidgets('navega para login ao tocar em Entrar', (tester) async {
      await tester.pumpWidget(_wrap(const SignUpPage()));

      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
