import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/pages/enter_page.dart';
import 'package:jacaloria/features/auth/widgets/enter_form.dart';
import 'package:jacaloria/features/auth/widgets/enter_header.dart';
import 'package:jacaloria/features/auth/widgets/enter_mascot.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_button.dart';
import 'package:jacaloria/shared/widgets/or_divider.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpEnterPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(const EnterPage()));
}

void main() {
  group('EnterPage - estrutura', () {
    testWidgets('renderiza EnterHeader, EnterForm e EnterMascot', (
      tester,
    ) async {
      await _pumpEnterPage(tester);

      expect(find.byType(EnterHeader), findsOneWidget);
      expect(find.byType(EnterForm), findsOneWidget);
      expect(find.byType(EnterMascot), findsOneWidget);
      expect(find.byType(OrDivider), findsOneWidget);
    });

    testWidgets('exibe os três AppButtons com as variantes corretas', (
      tester,
    ) async {
      await _pumpEnterPage(tester);

      final buttons = tester
          .widgetList<AppButton>(find.byType(AppButton))
          .toList();
      expect(buttons, hasLength(3));
      expect(buttons[0].variant, AppButtonVariant.google);
      expect(buttons[1].variant, AppButtonVariant.primary);
      expect(buttons[2].variant, AppButtonVariant.outline);
    });

    testWidgets('exibe os labels corretos nos botões', (tester) async {
      await _pumpEnterPage(tester);

      expect(find.text('Continuar com Google'), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
      expect(find.text('Já tenho uma conta'), findsOneWidget);
    });
  });

  group('EnterHeader - conteúdo', () {
    testWidgets('exibe título e subtítulo corretos', (tester) async {
      await tester.pumpWidget(_wrap(const EnterHeader()));

      expect(find.text('Vamos começar'), findsOneWidget);
      expect(
        find.text('Construa hábitos saudáveis todos os dias'),
        findsOneWidget,
      );
    });

    testWidgets('aplica espaçamento superior para afastar da status bar', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const EnterHeader()));

      final padding = tester.widget<Padding>(find.byType(Padding).first);
      final edgeInsets = padding.padding as EdgeInsets;

      expect(edgeInsets.top, AppSpacing.huge);
    });
  });

  group('EnterPage - comportamento', () {
    testWidgets('os três botões são tocáveis sem lançar exceção', (
      tester,
    ) async {
      await _pumpEnterPage(tester);

      await tester.tap(find.text('Continuar com Google'));
      await tester.tap(find.text('Criar conta'));
      await tester.tap(find.text('Já tenho uma conta'));
      await tester.pump();
    });
  });
}
