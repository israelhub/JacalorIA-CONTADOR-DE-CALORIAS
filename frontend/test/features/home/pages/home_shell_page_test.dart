import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/pages/home_shell_page.dart';
import 'package:jacaloria/shared/widgets/app_main_bottom_navigation.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('usa extendBody para barra sobreposta', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const HomeShellPage(
          performancePage: ColoredBox(color: Colors.red),
          homePage: ColoredBox(color: Colors.blue),
          missionsPage: ColoredBox(color: Colors.green),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.extendBody, isTrue);
  });

  testWidgets('swipe para a direita sai do inicio e vai para desempenho', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        const HomeShellPage(
          performancePage: ColoredBox(color: Colors.red),
          homePage: ColoredBox(color: Colors.blue),
          missionsPage: ColoredBox(color: Colors.green),
        ),
      ),
    );

    final pageView = tester.widget<PageView>(find.byType(PageView));
    final controller = pageView.controller!;

    expect(controller.page, closeTo(1, 0.001));
    expect(find.byType(AppMainBottomNavigation), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(320, 0));
    await tester.pumpAndSettle();

    expect(controller.page, closeTo(0, 0.001));
    expect(find.byType(AppMainBottomNavigation), findsOneWidget);
  });

  testWidgets('tap em desempenho troca para a pagina da esquerda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        const HomeShellPage(
          performancePage: ColoredBox(color: Colors.red),
          homePage: ColoredBox(color: Colors.blue),
          missionsPage: ColoredBox(color: Colors.green),
        ),
      ),
    );

    final pageView = tester.widget<PageView>(find.byType(PageView));
    final controller = pageView.controller!;

    expect(controller.page, closeTo(1, 0.001));

    await tester.tap(find.text('Desempenho'));
    await tester.pumpAndSettle();

    expect(controller.page, closeTo(0, 0.001));
    expect(find.byType(AppMainBottomNavigation), findsOneWidget);
  });

  testWidgets('tap em Missões troca para a pagina da direita', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        const HomeShellPage(
          performancePage: ColoredBox(color: Colors.red),
          homePage: ColoredBox(color: Colors.blue),
          missionsPage: ColoredBox(color: Colors.green),
        ),
      ),
    );

    final pageView = tester.widget<PageView>(find.byType(PageView));
    final controller = pageView.controller!;

    expect(controller.page, closeTo(1, 0.001));

    await tester.tap(find.text('Missões'));
    await tester.pumpAndSettle();

    expect(controller.page, closeTo(2, 0.001));
    expect(find.byType(AppMainBottomNavigation), findsOneWidget);
  });
}
