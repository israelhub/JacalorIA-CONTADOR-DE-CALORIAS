import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/pages/sign_up_page.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
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

      expect(find.text('Digite seu nome'), findsOneWidget);
      expect(find.text('Digite seu email'), findsOneWidget);
      expect(find.text('Digite sua senha'), findsOneWidget);
      expect(find.text('Confirme sua senha'), findsOneWidget);

      expect(find.byType(TextFormField), findsNWidgets(4));
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

    testWidgets('campos possuem borda inferior mais espessa', (tester) async {
      await tester.pumpWidget(_wrap(const SignUpPage()));

      final decoratedContainers = tester.widgetList<Container>(find.byType(Container)).where((container) {
        final decoration = container.decoration;
        if (decoration is! BoxDecoration || decoration.border is! Border) {
          return false;
        }

        final border = decoration.border! as Border;
        return border.bottom.width > border.top.width;
      }).toList();

      expect(decoratedContainers.length >= 4, isTrue);

      for (final container in decoratedContainers.take(4)) {
        final boxDecoration = container.decoration! as BoxDecoration;
        final border = boxDecoration.border! as Border;

        expect(border.top.width, AppSpacing.xs / 4);
        expect(border.left.width, AppSpacing.xs / 4);
        expect(border.right.width, AppSpacing.xs / 4);
        expect(border.bottom.width, AppSpacing.xs / 2);
      }
    });
  });
}
