import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/shared/widgets/app_back_page_header.dart';

void main() {
  const dpr = 3.0;
  const statusBarLogical = 48.0;
  const statusBarPhysical = statusBarLogical * dpr;

  testWidgets(
    'conteudo com scroll padding alinha com base da header no Android',
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
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                extendBodyBehindAppBar: true,
                appBar: const AppBackPageHeader(title: title),
                body: AppBackPageContent(
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: AppBackPageHeader.contentTopInset(context),
                    ),
                    children: const [
                      ColoredBox(
                        key: contentKey,
                        color: Colors.red,
                        child: SizedBox(height: 100, width: 100),
                      ),
                    ],
                  ),
                ),
              );
            },
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
    'quando padding.top raiz e 0, scroll padding alinha com AppBar',
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
      late double expectedInset;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expectedInset = AppBackPageHeader.contentTopInset(context);
              return Scaffold(
                extendBodyBehindAppBar: true,
                appBar: const AppBackPageHeader(title: title),
                body: AppBackPageContent(
                  child: ListView(
                    padding: EdgeInsets.only(top: expectedInset),
                    children: const [
                      ColoredBox(
                        key: contentKey,
                        color: Colors.red,
                        child: SizedBox(height: 100, width: 100),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final contentTop = tester.getTopLeft(find.byKey(contentKey)).dy;
      final chipBottom = tester
          .getBottomLeft(find.byType(AppBackPageHeaderBar))
          .dy;

      expect(contentTop, moreOrLessEquals(expectedInset, epsilon: 1));
      expect(
        expectedInset,
        moreOrLessEquals(
          statusBarLogical + AppBackPageHeader.barHeight,
          epsilon: 1,
        ),
      );
      expect(chipBottom, moreOrLessEquals(AppBackPageHeader.barHeight, epsilon: 1));
    },
  );

  testWidgets('header transparente nao usa AppBar Material', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBackPageHeader(title: 'Revisar análise'),
          body: AppBackPageContent(child: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(AppBackPageHeaderBar), findsOneWidget);
    expect(find.text('Revisar análise'), findsOneWidget);
  });

  testWidgets('scrollTopInset soma extra ao contentTopInset', (tester) async {
    tester.view.padding = const FakeViewPadding(top: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 48);
    addTearDown(tester.view.reset);

    late double inset;
    late double scrollTop;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            inset = AppBackPageHeader.contentTopInset(context);
            scrollTop = AppBackPageHeader.scrollTopInset(context, extra: 8);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(scrollTop, inset + 8);
  });

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
