import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/shared/widgets/app_anchored_menu.dart';

const _navBarHeight = 48.0;
const _screen = Size(390, 800);

Future<void> _pumpMenu(
  WidgetTester tester, {
  required Alignment childAlignment,
  Alignment targetAnchor = Alignment.bottomRight,
  Alignment followerAnchor = Alignment.topRight,
}) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(bottom: _navBarHeight, top: 24);
  tester.view.viewPadding = const FakeViewPadding(
    bottom: _navBarHeight,
    top: 24,
  );
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: childAlignment,
          child: AppAnchoredMenu(
            targetAnchor: targetAnchor,
            followerAnchor: followerAnchor,
            scaleAlignment: followerAnchor,
            childBuilder: (context, {required isOpen, required toggle}) {
              return GestureDetector(
                key: const ValueKey('menu-target'),
                onTap: toggle,
                child: const SizedBox(
                  width: 80,
                  height: 40,
                  child: ColoredBox(color: Colors.blue),
                ),
              );
            },
            menuBuilder: (context, {required close}) {
              return const Material(
                child: SizedBox(
                  key: ValueKey('anchored-menu'),
                  width: 176,
                  height: 160,
                  child: ColoredBox(color: Colors.red),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

Rect _safeArea() {
  return const Rect.fromLTWH(
    8,
    24 + 8,
    390 - 16,
    800 - 24 - _navBarHeight - 16,
  );
}

void main() {
  testWidgets('perto da barra nativa o menu abre para cima e fica visivel', (
    tester,
  ) async {
    await _pumpMenu(tester, childAlignment: Alignment.bottomRight);
    await tester.tap(find.byKey(const ValueKey('menu-target')));
    await tester.pumpAndSettle();

    final menu = tester.getRect(find.byKey(const ValueKey('anchored-menu')));
    final target = tester.getRect(find.byKey(const ValueKey('menu-target')));
    final safe = _safeArea();

    expect(menu.bottom, lessThanOrEqualTo(safe.bottom + 0.5));
    expect(menu.top, greaterThanOrEqualTo(safe.top - 0.5));
    expect(menu.left, greaterThanOrEqualTo(safe.left - 0.5));
    expect(menu.right, lessThanOrEqualTo(safe.right + 0.5));
    expect(menu.bottom, lessThanOrEqualTo(target.top + 0.5));
  });

  testWidgets('no topo da tela o menu permanece dentro da area visivel', (
    tester,
  ) async {
    await _pumpMenu(tester, childAlignment: Alignment.topLeft);
    await tester.tap(find.byKey(const ValueKey('menu-target')));
    await tester.pumpAndSettle();

    final menu = tester.getRect(find.byKey(const ValueKey('anchored-menu')));
    final safe = _safeArea();

    expect(menu.top, greaterThanOrEqualTo(safe.top - 0.5));
    expect(menu.bottom, lessThanOrEqualTo(safe.bottom + 0.5));
    expect(menu.left, greaterThanOrEqualTo(safe.left - 0.5));
    expect(menu.right, lessThanOrEqualTo(safe.right + 0.5));
  });
}
