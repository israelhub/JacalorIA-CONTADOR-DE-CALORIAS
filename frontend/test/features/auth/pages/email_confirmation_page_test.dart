import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/pages/email_confirmation_page.dart';
import 'package:jacaloria/features/onboarding/pages/welcome_page.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpEmailConfirmation(
  WidgetTester tester, {
  Future<bool> Function(String email, String code)? onVerifyEmail,
  Future<bool> Function(String email)? onResendCode,
}) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _wrap(
      EmailConfirmationPage(
        email: 'teste@jacaloria.app',
        onVerifyEmail: onVerifyEmail,
        onResendCode: onResendCode,
      ),
    ),
  );
}

void main() {
  group('EmailConfirmationPage - estrutura', () {
    testWidgets('renderiza título, subtítulo, 6 campos e botão confirmar', (
      tester,
    ) async {
      await _pumpEmailConfirmation(tester);

      expect(find.text('Confirme o seu e-mail'), findsOneWidget);
      expect(
        find.text('Enviamos um código para teste@jacaloria.app.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.text('Confirmar'), findsOneWidget);
      expect(find.text('Reenviar código'), findsOneWidget);
    });

    testWidgets('slots de código seguem dimensão esperada do Figma', (
      tester,
    ) async {
      await _pumpEmailConfirmation(tester);

      final firstSlot = find.byKey(const ValueKey('email-code-slot-0'));
      expect(firstSlot, findsOneWidget);

      final size = tester.getSize(firstSlot);
      expect(size.height, AppSpacing.huge + AppSpacing.sm);
      expect(size.width >= AppSpacing.huge, isTrue);
      expect(size.width <= AppSpacing.huge + AppSpacing.sm, isTrue);
    });

    testWidgets('botão confirmar fica inteiro visível sem corte', (
      tester,
    ) async {
      await _pumpEmailConfirmation(tester);

      final confirmButton = find.byKey(const ValueKey('email-confirm-button'));
      expect(confirmButton, findsOneWidget);

      final size = tester.getSize(confirmButton);
      expect(size.height, AppSpacing.huge + AppSpacing.xs);
    });

    testWidgets('campos aceitam apenas 1 dígito numérico', (tester) async {
      await _pumpEmailConfirmation(tester);

      final firstField = find.byType(TextField).first;
      await tester.enterText(firstField, 'ab12');
      await tester.pump();

      final field = tester.widget<TextField>(firstField);
      final controller = field.controller!;
      expect(controller.text, '1');
    });

    testWidgets('não navega para WelcomePage quando confirmação falha', (
      tester,
    ) async {
      await _pumpEmailConfirmation(
        tester,
        onVerifyEmail: (_, __) async => false,
      );

      for (var index = 0; index < 6; index++) {
        await tester.enterText(find.byType(TextField).at(index), '${index + 1}');
      }

      await tester.ensureVisible(find.text('Confirmar'));
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomePage), findsNothing);
      expect(find.text('Código inválido ou expirado.'), findsOneWidget);
    });

    testWidgets('navega para WelcomePage quando confirmação tem sucesso', (
      tester,
    ) async {
      await _pumpEmailConfirmation(
        tester,
        onVerifyEmail: (_, __) async => true,
      );

      for (var index = 0; index < 6; index++) {
        await tester.enterText(find.byType(TextField).at(index), '${index + 1}');
      }

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomePage), findsOneWidget);
    });
  });
}
