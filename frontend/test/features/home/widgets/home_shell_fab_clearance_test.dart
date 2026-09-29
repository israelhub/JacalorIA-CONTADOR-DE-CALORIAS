import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/pages/home_shell_page.dart';
import 'package:jacaloria/features/home/widgets/home_weight_quick_edit_button.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_floating_circle_button.dart';
import 'package:jacaloria/shared/widgets/app_main_bottom_navigation.dart';

void main() {
  testWidgets('FAB de peso fica acima da bottom nav com safe area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34, top: 47);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34, top: 47);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBody: true,
          body: Builder(
            builder: (context) {
              return Scaffold(
                backgroundColor: AppColors.surface,
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endFloat,
                floatingActionButton: Padding(
                  padding: EdgeInsets.only(
                    bottom: homeShellFabBottomInset(context),
                  ),
                  child: HomeWeightQuickEditButton(
                    userProfile: const {'weight': 70, 'weightUnit': 'kg'},
                    onWeightUpdated: (_) {},
                  ),
                ),
                body: const SizedBox.expand(),
              );
            },
          ),
          bottomNavigationBar: AppMainBottomNavigation(
            activeTab: AppMainBottomTab.home,
            onCenterActionTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fab = tester.getRect(
      find.byKey(const ValueKey('home-weight-quick-edit-button')),
    );
    final nav = tester.getRect(
      find.byKey(const ValueKey('app-bottom-nav-surface')),
    );

    expect(
      fab.bottom,
      closeTo(nav.top - homeShellFabNavGap, 1.5),
      reason: 'FAB should sit just above the nav. fab=$fab nav=$nav',
    );
  });

  testWidgets('controller abre editor sem botão visível', (tester) async {
    final controller = HomeWeightQuickEditController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeWeightQuickEditButton(
            userProfile: const {'weight': 70, 'weightUnit': 'kg'},
            onWeightUpdated: (_) {},
            controller: controller,
            showTrigger: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppFloatingCircleButton), findsNothing);

    controller.open();
    await tester.pumpAndSettle();

    expect(find.text('Atualizar peso'), findsOneWidget);
  });

  testWidgets('FAB no navigator aninhado do shell fica acima da bottom nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34, top: 47);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34, top: 47);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShellPage(
          homePage: Builder(
            builder: (context) {
              return Scaffold(
                backgroundColor: AppColors.surface,
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endFloat,
                floatingActionButton: Padding(
                  padding: EdgeInsets.only(
                    bottom: homeShellFabBottomInset(context),
                  ),
                  child: const SizedBox(
                    key: ValueKey('shell-nested-fab'),
                    width: 56,
                    height: 56,
                  ),
                ),
                body: const SizedBox.expand(),
              );
            },
          ),
          performancePage: const SizedBox.shrink(),
          missionsPage: const SizedBox.shrink(),
          socialPage: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fab = tester.getRect(find.byKey(const ValueKey('shell-nested-fab')));
    final nav = tester.getRect(
      find.byKey(const ValueKey('app-bottom-nav-surface')),
    );

    expect(
      fab.bottom,
      closeTo(nav.top - homeShellFabNavGap, 1.5),
      reason: 'FAB should sit just above the nav. fab=$fab nav=$nav',
    );
  });
}
