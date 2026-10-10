import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_bottom_navigation.dart';
import 'package:jacaloria/shared/widgets/app_main_bottom_navigation.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Align(alignment: Alignment.bottomCenter, child: child),
    ),
  );
}

AppBottomNavigationItem _navItem(WidgetTester tester, String label) {
  return tester.widget<AppBottomNavigationItem>(
    find.byWidgetPredicate(
      (widget) => widget is AppBottomNavigationItem && widget.label == label,
    ),
  );
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

void main() {
  testWidgets('overlay de loja pinta Mais e nao as tabs de swipe', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AppMainBottomNavigation(
          activeTab: AppMainBottomTab.home,
          overlayDestination: AppMainOverlayDestination.store,
          onCenterActionTap: _noop,
        ),
      ),
    );

    expect(_navItem(tester, 'Inicio').color, AppColors.divider);
    expect(_navItem(tester, 'Progresso').color, AppColors.divider);
    expect(_navItem(tester, 'Social').color, AppColors.divider);
    expect(_navItem(tester, 'Mais').color, AppColors.action500);
  });

  testWidgets('sem overlay a tab swipe volta a ficar verde', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppMainBottomNavigation(
          activeTab: AppMainBottomTab.social,
          onCenterActionTap: _noop,
        ),
      ),
    );

    expect(_navItem(tester, 'Social').color, AppColors.action500);
    expect(_navItem(tester, 'Inicio').color, AppColors.divider);
    expect(_navItem(tester, 'Mais').color, AppColors.divider);
  });

  testWidgets('painel Mais marca o destino overlay e nao a tab anterior', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AppMainBottomNavigation(
          activeTab: AppMainBottomTab.missions,
          overlayDestination: AppMainOverlayDestination.store,
          isMoreMenuOpen: true,
          onCenterActionTap: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Missões'), findsOneWidget);
    expect(find.text('Treino'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Loja'), findsOneWidget);
    expect(find.text('Notificações'), findsOneWidget);
    expect(find.text('Lembretes de refeição'), findsOneWidget);
    expect(find.text('Suporte'), findsOneWidget);

    expect(_morePanelLabelColor(tester, 'Loja'), AppColors.action500);
    expect(_morePanelLabelColor(tester, 'Missões'), AppColors.brand900Variant);
    expect(_morePanelLabelColor(tester, 'Treino'), AppColors.brand900Variant);
    expect(_morePanelLabelColor(tester, 'Perfil'), AppColors.brand900Variant);
  });

  testWidgets('Missões fica selecionada só sem overlay', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppMainBottomNavigation(
          activeTab: AppMainBottomTab.missions,
          isMoreMenuOpen: true,
          onCenterActionTap: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_morePanelLabelColor(tester, 'Missões'), AppColors.action500);
    expect(_morePanelLabelColor(tester, 'Loja'), AppColors.brand900Variant);
    expect(_navItem(tester, 'Mais').color, AppColors.action500);
  });
}

void _noop() {}
