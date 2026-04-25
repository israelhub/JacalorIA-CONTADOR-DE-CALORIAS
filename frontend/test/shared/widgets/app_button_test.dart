import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/shared/widgets/app_button.dart';

void main() {
  testWidgets('AppButton aplica animação de pressão ao tocar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppButton(
              label: 'Salvar',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final buttonFinder = find.text('Salvar');
    expect(buttonFinder, findsOneWidget);

    final scaleFinder = find.byType(AnimatedScale);
    expect(scaleFinder, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(buttonFinder));
    await tester.pump();

    final pressedScale = tester.widget<AnimatedScale>(scaleFinder).scale;
    expect(pressedScale, lessThan(1.0));

    await gesture.up();
  });
}