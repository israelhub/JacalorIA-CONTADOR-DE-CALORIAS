import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/onboarding/pages/personal_data_page.dart';
import 'package:jacaloria/features/onboarding/pages/welcome_page.dart';
import 'package:jacaloria/shared/widgets/app_button.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpWelcomePage(
  WidgetTester tester, {
  Size size = const Size(412, 917),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(const WelcomePage()));
}

void main() {
  group('WelcomePage - estrutura', () {
    testWidgets('renderiza textos, imagens e botão principal', (tester) async {
      await _pumpWelcomePage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Seja bem vindo(a) ao'), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome-logo-image')), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome-jaca-image')), findsOneWidget);
      final bubbleText = tester.widget<RichText>(
        find.byKey(const ValueKey('welcome-bubble-text')),
      );
      final fullText = bubbleText.text.toPlainText();
      expect(fullText.contains('Olá, meu nome é'), isTrue);
      expect(fullText.contains('Jaca'), isTrue);
      expect(fullText.contains('Quero te conhecer melhor!'), isTrue);
      expect(find.text('Começar'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('usa assets corretos e proporções do Figma', (tester) async {
      await _pumpWelcomePage(tester);
      await tester.pumpAndSettle();

      final logoImage = tester.widget<Image>(
        find.byKey(const ValueKey('welcome-logo-asset')),
      );
      expect(
        (logoImage.image as AssetImage).assetName,
        'assets/images/nome.png',
      );

      final jacaImage = tester.widget<Image>(
        find.byKey(const ValueKey('welcome-jaca-asset')),
      );
      expect(
        (jacaImage.image as AssetImage).assetName,
        'assets/images/Jaca_acenando_v2.png',
      );

      final mascotBox = tester.widget<SizedBox>(
        find.byKey(const ValueKey('welcome-mascot-box')),
      );
      expect(mascotBox.width, greaterThanOrEqualTo(215));
      expect(mascotBox.height, greaterThanOrEqualTo(225));

      final bubble = tester.widget<Container>(
        find.byKey(const ValueKey('welcome-bubble-container')),
      );
      final constraints = bubble.constraints;
      expect(constraints?.maxWidth, greaterThanOrEqualTo(115));
      expect(constraints?.maxHeight, greaterThanOrEqualTo(44));
    });

    testWidgets('executa animações de entrada', (tester) async {
      await _pumpWelcomePage(tester);

      expect(find.byType(AnimatedSlide), findsWidgets);
      expect(find.byType(AnimatedOpacity), findsWidgets);
    });

    testWidgets('mantem elementos principais centralizados em tela menor', (
      tester,
    ) async {
      await _pumpWelcomePage(tester, size: const Size(360, 800));
      await tester.pumpAndSettle();

      final pageCenterX = tester.getCenter(find.byType(Scaffold)).dx;
      final titleCenterX = tester
          .getCenter(find.text('Seja bem vindo(a) ao'))
          .dx;
      final logoCenterX = tester
          .getCenter(find.byKey(const ValueKey('welcome-logo-image')))
          .dx;
      final buttonCenterX = tester.getCenter(find.text('Começar')).dx;

      expect((titleCenterX - pageCenterX).abs(), lessThan(1.0));
      expect((logoCenterX - pageCenterX).abs(), lessThan(1.0));
      expect((buttonCenterX - pageCenterX).abs(), lessThan(1.0));
    });

    testWidgets('mantem jaca e balao grandes com sobreposicao forte', (
      tester,
    ) async {
      await _pumpWelcomePage(tester, size: const Size(360, 800));
      await tester.pumpAndSettle();

      final jacaRect = tester.getRect(
        find.byKey(const ValueKey('welcome-jaca-asset')),
      );
      final bubbleRect = tester.getRect(
        find.byKey(const ValueKey('welcome-bubble-container')),
      );

      expect(bubbleRect.left - jacaRect.right, lessThanOrEqualTo(8));
      expect(bubbleRect.left - jacaRect.right, greaterThanOrEqualTo(-80));
    });

    testWidgets('amplia jaca e balao em telas largas', (tester) async {
      await _pumpWelcomePage(tester, size: const Size(540, 960));
      await tester.pumpAndSettle();

      final mascotBox = tester.widget<SizedBox>(
        find.byKey(const ValueKey('welcome-mascot-box')),
      );
      expect(mascotBox.width, greaterThanOrEqualTo(280));

      final bubble = tester.widget<Container>(
        find.byKey(const ValueKey('welcome-bubble-container')),
      );
      expect(bubble.constraints?.maxWidth, greaterThanOrEqualTo(155));
      expect(bubble.constraints?.maxHeight, greaterThanOrEqualTo(50));
    });

    testWidgets('navega para PersonalDataPage ao tocar em Começar', (
      tester,
    ) async {
      await _pumpWelcomePage(tester);

      await tester.tap(find.text('Começar'));
      await tester.pumpAndSettle();

      expect(find.byType(PersonalDataPage), findsOneWidget);
    });
  });
}
