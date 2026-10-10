import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/shared/widgets/app_back_page_header.dart';

void main() {
  const dpr = 3.0;
  const statusBarLogical = 48.0;
  const statusBarPhysical = statusBarLogical * dpr;

  testWidgets(
    'conteudo comeca colado na base da header com status bar Android',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = dpr;
      tester.view.padding = const FakeViewPadding(
        top: statusBarPhysical,
        bottom: 72,
      );
      tester.view.viewPadding = const FakeViewPadding(
        top: statusBarPhysical,
        bottom: 72,
      );
      addTearDown(tester.view.reset);

      const contentKey = ValueKey('page-content');
      const title = 'Nova refeição';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBackPageHeader(title: title),
            body: AppBackPageContent(
              child: ColoredBox(
                key: contentKey,
                color: Colors.red,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final contentTop = tester.getTopLeft(find.byKey(contentKey)).dy;
      final chipBottom = tester
          .getBottomLeft(find.byType(AppBackPageHeaderBar))
          .dy;
      final expected = statusBarLogical + AppBackPageHeader.barHeight;

      expect(contentTop, moreOrLessEquals(expected, epsilon: 1));
      expect(
        contentTop,
        moreOrLessEquals(chipBottom, epsilon: 12),
        reason:
            'Conteudo deve comecar junto da base dos chips, sem faixa extra',
      );
    },
  );

  testWidgets(
    'quando padding.top raiz e 0, alinha com a altura real do AppBar',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = dpr;
      tester.view.padding = FakeViewPadding.zero;
      tester.view.viewPadding = const FakeViewPadding(
        top: statusBarPhysical,
        bottom: 72,
      );
      addTearDown(tester.view.reset);

      const contentKey = ValueKey('page-content');
      const title = 'Detalhes';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBackPageHeader(title: title),
            body: AppBackPageContent(
              child: ColoredBox(
                key: contentKey,
                color: Colors.red,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final contentTop = tester.getTopLeft(find.byKey(contentKey)).dy;
      final chipBottom = tester
          .getBottomLeft(find.byType(AppBackPageHeaderBar))
          .dy;

      expect(contentTop, moreOrLessEquals(AppBackPageHeader.barHeight, epsilon: 1));
      expect(
        contentTop,
        moreOrLessEquals(chipBottom, epsilon: 12),
        reason: 'Gap extra entre chips e conteudo no edge-to-edge',
      );
    },
  );

  testWidgets(
    'contentTopInset fora do body soma status bar + barHeight',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = dpr;
      tester.view.padding = const FakeViewPadding(
        top: statusBarPhysical,
        bottom: 72,
      );
      tester.view.viewPadding = const FakeViewPadding(
        top: statusBarPhysical,
        bottom: 72,
      );
      addTearDown(tester.view.reset);

      late double insetOutsideBody;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              insetOutsideBody = AppBackPageHeader.contentTopInset(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        insetOutsideBody,
        moreOrLessEquals(
          statusBarLogical + AppBackPageHeader.barHeight,
          epsilon: 0.1,
        ),
      );
    },
  );
}
