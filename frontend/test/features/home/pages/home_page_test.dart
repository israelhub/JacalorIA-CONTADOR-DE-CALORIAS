import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jacaloria/features/home/pages/home_page.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpHomePage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(const HomePage()));
}

void main() {
  group('HomePage', () {
    testWidgets('bottom bar renderiza o layout compacto com icones svg', (
      tester,
    ) async {
      await _pumpHomePage(tester);
      await tester.pumpAndSettle();

      final navSurface = find.byKey(const ValueKey('home-bottom-nav-surface'));
      final cameraButton = find.byKey(
        const ValueKey('home-bottom-camera-button'),
      );

      expect(find.byType(SvgPicture), findsNWidgets(4));
      expect(navSurface, findsOneWidget);
      expect(cameraButton, findsOneWidget);
      expect(tester.getSize(navSurface).height, 56);
      expect(
        tester.getTopLeft(cameraButton).dy,
        lessThan(tester.getTopLeft(navSurface).dy),
      );

      final homeIcon = tester.widget<SvgPicture>(
        find.byKey(const ValueKey('home-bottom-icon-inicio')),
      );
      final calendarIcon = tester.widget<SvgPicture>(
        find.byKey(const ValueKey('home-bottom-icon-calendario')),
      );

      expect(homeIcon.colorFilter, isNotNull);
      expect(calendarIcon.colorFilter, isNotNull);
      expect(homeIcon.width, 28);
      expect(homeIcon.height, 28);
      expect(
        tester
                .getTopLeft(
                  find.byKey(const ValueKey('home-bottom-icon-calendario')),
                )
                .dx -
            tester.getTopLeft(navSurface).dx,
        greaterThan(12),
      );

      final iconBottom = tester.getBottomLeft(
        find.byKey(const ValueKey('home-bottom-icon-inicio')),
      );
      final labelTop = tester.getTopLeft(
        find.byKey(const ValueKey('home-bottom-label-inicio')),
      );

      expect(labelTop.dy - iconBottom.dy, lessThanOrEqualTo(1));
    });
  });
}
