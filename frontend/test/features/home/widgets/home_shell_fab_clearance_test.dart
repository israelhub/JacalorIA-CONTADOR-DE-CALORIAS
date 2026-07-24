import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      lessThanOrEqualTo(nav.top - homeShellFabNavGap + 0.5),
      reason: 'FAB should clear the nav with a gap. fab=$fab nav=$nav',
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
}
