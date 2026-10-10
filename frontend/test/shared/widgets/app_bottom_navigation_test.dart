import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_bottom_navigation.dart';
import 'package:jacaloria/shared/widgets/app_nav_icons.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

Widget _wrap(
  Widget child, {
  EdgeInsets viewPadding = EdgeInsets.zero,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        viewPadding: viewPadding,
      ),
      child: child,
    ),
  );
}

void main() {
  testWidgets('renderiza itens, superficie e botao central', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppBottomNavigation(
          items: [
            AppBottomNavigationItem(
              label: 'Calendário',
              icon: AppNavIcons.performance(selected: false),
              color: AppColors.divider,
              iconKey: const ValueKey('bottom-icon-calendar'),
            ),
            AppBottomNavigationItem(
              label: 'Início',
              icon: AppNavIcons.home(selected: true),
              color: AppColors.action500,
              iconKey: const ValueKey('bottom-icon-home'),
            ),
            AppBottomNavigationItem(
              label: 'Missões',
              icon: AppNavIcons.missions(selected: false),
              color: AppColors.divider,
              iconKey: const ValueKey('bottom-icon-missions'),
            ),
            AppBottomNavigationItem(
              label: 'Social',
              icon: AppNavIcons.social(selected: false),
              color: AppColors.divider,
              iconKey: const ValueKey('bottom-icon-social'),
            ),
          ],
          onCenterActionTap: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(PhosphorIcon), findsWidgets);
    expect(
      find.byKey(const ValueKey('app-bottom-nav-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('app-bottom-nav-center-action')),
      findsOneWidget,
    );

    final homeIcon = tester.widget<PhosphorIcon>(
      find.byKey(const ValueKey('bottom-icon-home')),
    );

    expect(homeIcon.color, AppColors.action500);
    final surfaceDecoration = tester.widget<Container>(
      find.byKey(const ValueKey('app-bottom-nav-surface')),
    ).decoration as BoxDecoration;

    expect(surfaceDecoration.color, AppColors.surface);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('app-bottom-nav-surface')))
          .height,
      appBottomNavCardHeight,
    );
  });

  testWidgets('reserva padding inferior da safe area', (tester) async {
    await tester.pumpWidget(
      _wrap(
        viewPadding: const EdgeInsets.only(bottom: 34),
        AppBottomNavigation(
          items: [
            AppBottomNavigationItem(
              label: 'Calendário',
              icon: AppNavIcons.performance(selected: false),
              color: AppColors.divider,
            ),
            AppBottomNavigationItem(
              label: 'Início',
              icon: AppNavIcons.home(selected: true),
              color: AppColors.action500,
            ),
            AppBottomNavigationItem(
              label: 'Missões',
              icon: AppNavIcons.missions(selected: false),
              color: AppColors.divider,
            ),
            AppBottomNavigationItem(
              label: 'Social',
              icon: AppNavIcons.social(selected: false),
              color: AppColors.divider,
            ),
          ],
          onCenterActionTap: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(find.byKey(const ValueKey('app-bottom-nav-surface')))
          .height,
      appBottomNavCardHeight + 34,
    );
  });
}
