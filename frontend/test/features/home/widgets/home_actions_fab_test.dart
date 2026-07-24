import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jacaloria/core/notifications/in_app_message_store.dart';
import 'package:jacaloria/features/home/widgets/home_actions_fab.dart';
import 'package:jacaloria/features/home/widgets/home_weight_quick_edit_button.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_main_bottom_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await InAppMessageStore.instance.resetForTest();
  });

  testWidgets('FAB expansível da home fica acima da bottom nav', (
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
                  child: HomeActionsFab(
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

    final fab = tester.getRect(find.byKey(const ValueKey('home-actions-fab')));
    final nav = tester.getRect(
      find.byKey(const ValueKey('app-bottom-nav-surface')),
    );

    expect(
      fab.bottom,
      lessThanOrEqualTo(nav.top - homeShellFabNavGap + 0.5),
      reason: 'FAB should clear the nav with a gap. fab=$fab nav=$nav',
    );
  });

  testWidgets('abre menu com peso e notificações e mostra badge', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'meal_reminders_master_enabled': false,
    });
    await InAppMessageStore.instance.resetForTest();
    await InAppMessageStore.instance.addMessage(
      title: 'Teste',
      body: 'Corpo',
      source: 'catalog',
      id: 'badge-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: HomeActionsFab(
            userProfile: const {'weight': 70, 'weightUnit': 'kg'},
            onWeightUpdated: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Abrir ações da home'));
    await tester.pumpAndSettle();

    expect(find.text('Peso'), findsOneWidget);
    expect(find.text('Notificações'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-fab-notifications')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expandable-fab-action-badge-1')),
      findsOneWidget,
    );
  });
}
