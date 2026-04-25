import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_bottom_navigation.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('renderiza itens, superficie e botao central', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppBottomNavigation(
          items: const [
            AppBottomNavigationItem(
              label: 'Calendário',
              iconAsset: 'assets/icons/calendar.svg',
              color: AppColors.divider,
              labelKey: ValueKey('bottom-label-calendar'),
              iconKey: ValueKey('bottom-icon-calendar'),
            ),
            AppBottomNavigationItem(
              label: 'Início',
              iconAsset: 'assets/icons/home.svg',
              color: AppColors.action500,
              labelKey: ValueKey('bottom-label-home'),
              iconKey: ValueKey('bottom-icon-home'),
            ),
            AppBottomNavigationItem(
              label: 'Missões',
              iconAsset: 'assets/icons/mission.svg',
              color: AppColors.divider,
              labelKey: ValueKey('bottom-label-missions'),
              iconKey: ValueKey('bottom-icon-missions'),
            ),
            AppBottomNavigationItem(
              label: 'Social',
              iconAsset: 'assets/icons/profile.svg',
              color: AppColors.divider,
              labelKey: ValueKey('bottom-label-social'),
              iconKey: ValueKey('bottom-icon-social'),
            ),
          ],
          onCenterActionTap: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsNWidgets(4));
    expect(
      find.byKey(const ValueKey('app-bottom-nav-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('app-bottom-nav-center-action')),
      findsOneWidget,
    );

    final homeIcon = tester.widget<SvgPicture>(
      find.byKey(const ValueKey('bottom-icon-home')),
    );

    expect(homeIcon.colorFilter, isNotNull);
    final surfaceDecoration = tester.widget<Container>(
      find.byKey(const ValueKey('app-bottom-nav-surface')),
    ).decoration as BoxDecoration;

    expect(surfaceDecoration.border, isA<Border>());
    expect(
      (surfaceDecoration.border as Border).top.color,
      AppColors.borderBrandAlt,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('app-bottom-nav-surface')))
          .height,
      56,
    );
  });
}
