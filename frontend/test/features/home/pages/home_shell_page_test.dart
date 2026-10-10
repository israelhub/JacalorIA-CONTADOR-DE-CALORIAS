import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/pages/home_shell_page.dart';
import 'package:jacaloria/features/profile/pages/profile_page.dart';
import 'package:jacaloria/features/reminders/pages/meal_reminders_page.dart';
import 'package:jacaloria/features/support/pages/support_page.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_bottom_navigation.dart';
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

Finder _navItemFinder(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is AppBottomNavigationItem && widget.label == label,
  );
}

Future<void> _openMoreMenu(WidgetTester tester) async {
  await tester.tap(_navItemFinder('Mais'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 650));
}

AppBottomNavigationItem _navItem(WidgetTester tester, String label) {
  return tester.widget<AppBottomNavigationItem>(_navItemFinder(label));
}

Color _morePanelLabelColor(WidgetTester tester, String label) {
  return tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('app-more-destinations-panel')),
          matching: find.text(label),
        ),
      )
      .style!
      .color!;
}

Future<void> _pumpPhoneShell(WidgetTester tester, {Widget? homePage}) async {
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
        homePage: homePage ?? const ColoredBox(color: Colors.blue),
        missionsPage: const ColoredBox(
          color: Colors.green,
          child: Text('missoes-page'),
        ),
        socialPage: const ColoredBox(
          color: Colors.orange,
          child: Text('social-page'),
        ),
        workoutPage: const ColoredBox(
          color: Colors.purple,
          child: Text('treino-page'),
        ),
      ),
    ),
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

    expect(_navItemFinder('Mais'), findsOneWidget);
    expect(find.text('Missões'), findsNothing);

    await tester.tap(_navItemFinder('Mais'));
    await tester.pumpAndSettle();

    expect(find.text('Missões'), findsOneWidget);
    expect(find.text('Treino'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Loja'), findsOneWidget);
    expect(find.text('Notificações'), findsOneWidget);
    expect(find.text('Lembretes de refeição'), findsOneWidget);
    expect(find.text('Suporte'), findsOneWidget);

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

    await tester.tap(_navItemFinder('Mais'));
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

    await tester.tap(_navItemFinder('Progresso'));
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

    await tester.tap(_navItemFinder('Social'));
    await tester.pumpAndSettle();

    expect(controller.page, closeTo(2, 0.001));
    expect(find.byType(AppMainBottomNavigation), findsOneWidget);
  });

  testWidgets('overlay de perfil pinta Mais e tira o verde das tabs', (
    tester,
  ) async {
    await _pumpPhoneShell(tester);

    expect(_navItem(tester, 'Inicio').color, AppColors.action500);
    expect(_navItem(tester, 'Mais').color, AppColors.divider);

    await _openMoreMenu(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('app-more-destinations-panel')),
        matching: find.text('Perfil'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(
      HomeShellPage.maybeController?.overlayDestination,
      AppMainOverlayDestination.profile,
    );
    expect(_navItem(tester, 'Inicio').color, AppColors.divider);
    expect(_navItem(tester, 'Progresso').color, AppColors.divider);
    expect(_navItem(tester, 'Social').color, AppColors.divider);
    expect(_navItem(tester, 'Mais').color, AppColors.action500);

    await _openMoreMenu(tester);
    expect(
      _morePanelLabelColor(tester, 'Perfil'),
      AppColors.action500,
    );
    expect(
      _morePanelLabelColor(tester, 'Missões'),
      AppColors.brand900Variant,
    );
    expect(
      _morePanelLabelColor(tester, 'Loja'),
      AppColors.brand900Variant,
    );

    await tester.tap(_navItemFinder('Mais'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(ProfilePage), findsNothing);
    expect(
      HomeShellPage.maybeController?.overlayDestination,
      AppMainOverlayDestination.none,
    );
    expect(_navItem(tester, 'Inicio').color, AppColors.action500);
    expect(_navItem(tester, 'Mais').color, AppColors.divider);
  });

  testWidgets('loja no overlay seleciona Loja e nao Missões', (tester) async {
    await _pumpPhoneShell(tester);

    await _openMoreMenu(tester);
    await tester.tap(find.text('Missões'));
    await tester.pumpAndSettle();

    expect(find.text('missoes-page'), findsOneWidget);
    expect(_navItem(tester, 'Mais').color, AppColors.action500);

    await _openMoreMenu(tester);
    expect(
      _morePanelLabelColor(tester, 'Missões'),
      AppColors.action500,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('app-more-destinations-panel')),
        matching: find.text('Loja'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      HomeShellPage.maybeController?.overlayDestination,
      AppMainOverlayDestination.store,
    );
    expect(_navItem(tester, 'Inicio').color, AppColors.divider);
    expect(_navItem(tester, 'Mais').color, AppColors.action500);

    await tester.tap(_navItemFinder('Mais'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(_morePanelLabelColor(tester, 'Loja'), AppColors.action500);
    expect(_morePanelLabelColor(tester, 'Missões'), AppColors.brand900Variant);
    expect(_morePanelLabelColor(tester, 'Treino'), AppColors.brand900Variant);
  });

  testWidgets('Mais abre lembretes e suporte pelo nested navigator', (
    tester,
  ) async {
    await _pumpPhoneShell(tester);

    await _openMoreMenu(tester);
    await tester.tap(find.text('Lembretes de refeição'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(MealRemindersPage), findsOneWidget);
    expect(
      HomeShellPage.maybeController?.overlayDestination,
      AppMainOverlayDestination.reminders,
    );
    expect(_navItem(tester, 'Mais').color, AppColors.action500);
    expect(_navItem(tester, 'Inicio').color, AppColors.divider);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await _openMoreMenu(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('app-more-destinations-panel')),
        matching: find.text('Suporte'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(SupportPage), findsOneWidget);
    expect(
      HomeShellPage.maybeController?.overlayDestination,
      AppMainOverlayDestination.support,
    );
    expect(_navItem(tester, 'Mais').color, AppColors.action500);
  });
}
