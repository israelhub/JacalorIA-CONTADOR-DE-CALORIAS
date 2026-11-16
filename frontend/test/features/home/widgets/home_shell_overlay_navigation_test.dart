import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/pages/enter_page.dart';
import 'package:jacaloria/features/avatar_frames/pages/avatar_frame_store_page.dart';
import 'package:jacaloria/features/home/pages/home_shell_page.dart';
import 'package:jacaloria/features/profile/pages/profile_page.dart';
import 'package:jacaloria/features/social/pages/social_create_group_page.dart';
import 'package:jacaloria/features/support/pages/support_page.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_main_bottom_navigation.dart';
import 'package:jacaloria/shared/widgets/app_page_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OpenOverlayPage extends StatelessWidget {
  const _OpenOverlayPage({required this.page});

  final Widget page;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.blue,
      child: Center(
        child: TextButton(
          onPressed: () => context.pushSlidePage(page),
          child: const Text('abrir overlay'),
        ),
      ),
    );
  }
}

class _OverlayDummyPage extends StatelessWidget {
  const _OverlayDummyPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Text('Overlay dummy')),
    );
  }
}

Widget _shell({required Widget homePage}) {
  return MaterialApp(
    home: HomeShellPage(
      homePage: homePage,
      performancePage: const ColoredBox(
        color: Colors.red,
        child: Text('desempenho-page'),
      ),
      missionsPage: const ColoredBox(
        color: Colors.green,
        child: Text('missoes-page'),
      ),
      socialPage: const ColoredBox(
        color: Colors.orange,
        child: Text('social-page'),
      ),
    ),
  );
}

Future<void> _openOverlay(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_shell(homePage: _OpenOverlayPage(page: page)));
  await tester.tap(find.text('abrir overlay'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('overlay do shell mantém uma única bottom nav', (tester) async {
    await _openOverlay(tester, const _OverlayDummyPage());

    expect(find.text('Overlay dummy'), findsOneWidget);
    expect(find.byType(AppMainBottomNavigation), findsOneWidget);
  });

  testWidgets('tap em Missões fecha o overlay e abre a aba', (tester) async {
    await _openOverlay(tester, const _OverlayDummyPage());

    await tester.tap(find.text('Missões'));
    await tester.pumpAndSettle();

    expect(find.text('Overlay dummy'), findsNothing);
    expect(find.text('missoes-page'), findsOneWidget);
    expect(find.byType(AppMainBottomNavigation), findsOneWidget);
  });

  testWidgets('perfil empilhado mantém a bottom nav do shell', (tester) async {
    await _openOverlay(
      tester,
      const ProfilePage(initialProfile: {'name': 'Ana'}),
    );
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.byType(AppMainBottomNavigation), findsOneWidget);
  });

  testWidgets('criar grupo deixa o botão acima da bottom nav', (tester) async {
    tester.view.physicalSize = const Size(412, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34, top: 47);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34, top: 47);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      _shell(
        homePage: const _OpenOverlayPage(
          page: SocialCreateGroupPage(),
        ),
      ),
    );
    await tester.tap(find.text('abrir overlay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final scrollable = find
        .descendant(
          of: find.byType(SocialCreateGroupPage),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        )
        .first;
    await tester.drag(scrollable, const Offset(0, -4000));
    await tester.pumpAndSettle();

    final button = tester.getRect(find.text('Criar grupo'));
    final nav = tester.getRect(
      find.descendant(
        of: find.byType(SocialCreateGroupPage),
        matching: find.byKey(const ValueKey('app-bottom-nav-surface')),
      ),
    );

    expect(button.bottom, lessThanOrEqualTo(nav.top));
  });

  testWidgets('criar grupo mostra a bottom nav', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _shell(
        homePage: const _OpenOverlayPage(
          page: SocialCreateGroupPage(),
        ),
      ),
    );
    await tester.tap(find.text('abrir overlay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Novo grupo'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SocialCreateGroupPage),
        matching: find.byType(AppMainBottomNavigation),
      ),
      findsOneWidget,
    );
  });

  testWidgets('suporte fora do shell nao mostra a bottom nav', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupportPage()));

    expect(find.byType(AppMainBottomNavigation), findsNothing);
  });

  testWidgets('sair do perfil no overlay remove a bottom nav', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _shell(
        homePage: const _OpenOverlayPage(
          page: ProfilePage(initialProfile: {'name': 'Ana'}),
        ),
      ),
    );
    await tester.tap(find.text('abrir overlay'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Sair'),
      500,
      scrollable: find
          .descendant(
            of: find.byType(ProfilePage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.byType(EnterPage), findsOneWidget);
    expect(find.byType(AppMainBottomNavigation), findsNothing);
  });

  testWidgets(
    'pushAndRemoveUntilSlidePage substitui a rota raiz e tira a nav',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (context) {
                    return TextButton(
                      onPressed: () {
                        context.pushAndRemoveUntilSlidePage(
                          const Scaffold(body: Text('tela-login')),
                          (route) => false,
                        );
                      },
                      child: const Text('sair'),
                    );
                  },
                );
              },
            ),
            bottomNavigationBar: const SizedBox(
              height: 56,
              child: Text('nav-shell'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('sair'));
      await tester.pumpAndSettle();

      expect(find.text('tela-login'), findsOneWidget);
      expect(find.text('nav-shell'), findsNothing);
    },
  );

  testWidgets('loja nao deixa faixa acima da bottom nav', (tester) async {
    tester.view.physicalSize = const Size(412, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34, top: 47);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34, top: 47);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      _shell(
        homePage: const _OpenOverlayPage(
          page: AvatarFrameStorePage(
            initialGoldBalance: 10,
            profile: {'name': 'Ana'},
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir overlay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Loja'), findsOneWidget);

    final content = tester.getRect(find.byType(RefreshIndicator));
    final nav = tester.getRect(
      find.byKey(const ValueKey('app-bottom-nav-surface')),
    );

    expect(content.bottom, lessThanOrEqualTo(nav.top + 0.5));
    expect(nav.top - content.bottom, lessThan(AppSpacing.sm));
  });
}
