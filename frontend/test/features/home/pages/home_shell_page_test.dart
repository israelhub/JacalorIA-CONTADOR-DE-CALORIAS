import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/pages/home_shell_page.dart';
import 'package:jacaloria/shared/widgets/app_main_bottom_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_steps_service.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

HomeShellPage _shell({
  Widget? performancePage,
  Widget? homePage,
  Widget? missionsPage,
  Widget? socialPage,
  Widget? workoutPage,
}) {
  return HomeShellPage(
    performancePage: performancePage,
    homePage: homePage,
    missionsPage: missionsPage,
    socialPage: socialPage,
    workoutPage: workoutPage,
    stepsService: FakeStepsService(),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('barra flutua sobre o body em Stack', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _shell(
          performancePage: const ColoredBox(color: Colors.red),
          homePage: const ColoredBox(color: Colors.blue),
          missionsPage: const ColoredBox(color: Colors.green),
          socialPage: const ColoredBox(color: Colors.orange),
        ),
      ),
    );

    expect(find.byType(AppMainBottomNavigation), findsOneWidget);
    final nav = tester.getRect(find.byType(AppMainBottomNavigation));
    final body = tester.getRect(find.byType(Navigator).first);
    expect(nav.bottom, closeTo(body.bottom, 0.5));
    expect(find.descendant(
      of: find.byType(Stack).first,
      matching: find.byType(AppMainBottomNavigation),
    ), findsOneWidget);
  });

  testWidgets('swipe para a direita sai do inicio e vai para progresso', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        _shell(
          performancePage: const ColoredBox(color: Colors.red),
          homePage: const ColoredBox(color: Colors.blue),
          missionsPage: const ColoredBox(color: Colors.green),
          socialPage: const ColoredBox(color: Colors.orange),
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

  testWidgets('arrasto vertical nao troca de aba', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        _shell(
          performancePage: const ColoredBox(color: Colors.red),
          homePage: const ColoredBox(color: Colors.blue),
          missionsPage: const ColoredBox(color: Colors.green),
          socialPage: const ColoredBox(color: Colors.orange),
        ),
      ),
    );

    final pageView = tester.widget<PageView>(find.byType(PageView));
    final controller = pageView.controller!;

    expect(controller.page, closeTo(1, 0.001));

    await tester.timedDrag(
      find.byType(PageView),
      const Offset(40, 280),
      const Duration(milliseconds: 280),
    );
    await tester.pumpAndSettle();

    expect(controller.page, closeTo(1, 0.001));
  });

  testWidgets('tap em Mais abre missões acima da barra', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        _shell(
          performancePage: const ColoredBox(
            color: Colors.red,
            child: Text('desempenho-page'),
          ),
          homePage: const ColoredBox(color: Colors.blue),
          missionsPage: const ColoredBox(
            color: Colors.green,
            child: Text('missoes-page'),
          ),
          socialPage: const ColoredBox(color: Colors.orange),
          workoutPage: const ColoredBox(
            color: Colors.purple,
            child: Text('treino-page'),
          ),
        ),
      ),
    );

    expect(find.text('Mais'), findsOneWidget);
    expect(find.text('Missões'), findsNothing);

    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();

    expect(find.text('Missões'), findsOneWidget);
    expect(find.text('Treino'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Loja'), findsOneWidget);
    expect(find.text('Notificações'), findsOneWidget);

    await tester.tap(find.text('Missões'));
    await tester.pumpAndSettle();

    expect(find.text('missoes-page'), findsOneWidget);
    expect(find.byType(AppMainBottomNavigation), findsOneWidget);
  });

  testWidgets('tap em Mais abre a pagina de treino', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        _shell(
          homePage: const ColoredBox(color: Colors.blue),
          socialPage: const ColoredBox(color: Colors.orange),
          workoutPage: const ColoredBox(
            color: Colors.purple,
            child: Text('treino-page'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Treino'));
    await tester.pumpAndSettle();

    expect(find.text('treino-page'), findsOneWidget);
  });

  testWidgets('tap em Progresso troca para a pagina da esquerda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        _shell(
          performancePage: const ColoredBox(color: Colors.red),
          homePage: const ColoredBox(color: Colors.blue),
          missionsPage: const ColoredBox(color: Colors.green),
          socialPage: const ColoredBox(color: Colors.orange),
        ),
      ),
    );

    final pageView = tester.widget<PageView>(find.byType(PageView));
    final controller = pageView.controller!;

    expect(controller.page, closeTo(1, 0.001));

    await tester.tap(find.text('Progresso'));
    await tester.pumpAndSettle();

    expect(controller.page, closeTo(0, 0.001));
    expect(find.byType(AppMainBottomNavigation), findsOneWidget);
  });

  testWidgets('tap em Social troca para a pagina da direita', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        _shell(
          performancePage: const ColoredBox(color: Colors.red),
          homePage: const ColoredBox(color: Colors.blue),
          missionsPage: const ColoredBox(color: Colors.green),
          socialPage: const ColoredBox(color: Colors.orange),
        ),
      ),
    );

    final pageView = tester.widget<PageView>(find.byType(PageView));
    final controller = pageView.controller!;

    expect(controller.page, closeTo(1, 0.001));

    await tester.tap(find.text('Social'));
    await tester.pumpAndSettle();

    expect(controller.page, closeTo(2, 0.001));
    expect(find.byType(AppMainBottomNavigation), findsOneWidget);
  });
}
