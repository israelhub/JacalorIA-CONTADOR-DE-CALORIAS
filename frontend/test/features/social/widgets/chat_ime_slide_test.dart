import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/widgets/chat_ime_slide.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<void> pumpLift(
    WidgetTester tester, {
    required double height,
    required double inset,
    double safeBottom = 34,
  }) {
    tester.view.physicalSize = Size(390, height);
    tester.view.devicePixelRatio = 1;
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: Size(390, height),
          viewInsets: EdgeInsets.only(bottom: inset),
          viewPadding: EdgeInsets.only(bottom: safeBottom),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 390,
            height: height,
            child: const ChatKeyboardLift(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  key: ValueKey('ime-child'),
                  width: 40,
                  height: 40,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double childBottom(WidgetTester tester) {
    return tester.getRect(find.byKey(const ValueKey('ime-child'))).bottom;
  }

  testWidgets('sem teclado o filho fica no fundo', (tester) async {
    addTearDown(tester.view.reset);
    await pumpLift(tester, height: 800, inset: 0);

    expect(childBottom(tester), closeTo(800, 0.5));
  });

  testWidgets('desliza o inset menos a safe area quando a janela nao encolhe', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await pumpLift(tester, height: 800, inset: 0);
    await pumpLift(tester, height: 800, inset: 320);

    expect(
      tester.getSize(find.byKey(const ValueKey('ime-child'))),
      const Size(40, 40),
    );
    expect(childBottom(tester), closeTo(800 - (320 - 34), 0.5));
  });

  testWidgets('nao sobe de novo se a janela ja encolheu com o teclado', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await pumpLift(tester, height: 800, inset: 0);
    await pumpLift(tester, height: 480, inset: 320);

    expect(childBottom(tester), closeTo(480, 0.5));
  });
}
