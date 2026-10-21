import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/service/auth_service.dart';
import 'package:jacaloria/features/home/pages/home_shell_page.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_coach_mark_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_steps_service.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.theme, home: child);
}

Future<void> _tapNextWhenReady(WidgetTester tester, String text) async {
  await tester.pump(const Duration(milliseconds: 4500));
  expect(find.textContaining(text), findsOneWidget);
  await tester.ensureVisible(find.text('Próximo'));
  await tester.pump();
  await tester.tap(find.text('Próximo'));
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AuthService.globalUser = null;
  });

  tearDown(() {
    AuthService.globalUser = null;
  });

  testWidgets('force mode percorre Home, Mais, Missões, Loja, Social e abas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        HomeShellPage(
          productTourMode: HomeShellProductTourMode.force,
          stepsService: FakeStepsService(),
          performancePage: const ColoredBox(
            color: Colors.red,
            child: Text('desempenho-page'),
          ),
          homePage: const ColoredBox(
            color: Colors.blue,
            child: Text('home-page'),
          ),
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(AppCoachMarkOverlay), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);

    await tester.tap(find.text('Próximo'));
    await tester.pump();
    await _tapNextWhenReady(tester, 'e o seu objetivo');

    await _tapNextWhenReady(tester, 'Adicionar refeição');

    await tester.pump(const Duration(milliseconds: 4500));
    expect(find.text('Abrir Missões'), findsOneWidget);
    expect(find.textContaining('outras funções existentes'), findsOneWidget);

    await tester.tap(find.text('Abrir Missões'));
    await tester.pump();
    await _tapNextWhenReady(tester, 'ouro e XP');

    await _tapNextWhenReady(tester, 'acessando a loja');

    await tester.pump(const Duration(milliseconds: 4500));
    expect(find.textContaining('consistência juntos'), findsOneWidget);

    await tester.tap(find.text('Próximo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4500));
    expect(find.text('Abas do Social'), findsOneWidget);
    expect(find.textContaining('usuários do app'), findsOneWidget);

    await tester.tap(find.text('Próximo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4500));
    expect(find.text('Progresso'), findsWidgets);

    await tester.tap(find.text('Concluir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AppCoachMarkOverlay), findsNothing);
    expect(find.text('Parabéns por concluir o tutorial!'), findsOneWidget);
    expect(find.textContaining('encontrar outros'), findsOneWidget);
    expect(find.textContaining('equipados através da loja'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
    await tester.tap(find.text('Começar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('home-page'), findsOneWidget);
  });

  testWidgets('off mode nao inicia tour', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HomeShellPage(
          productTourMode: HomeShellProductTourMode.off,
          stepsService: FakeStepsService(),
          homePage: const ColoredBox(color: Colors.blue, child: Text('home')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AppCoachMarkOverlay), findsNothing);
  });
}
