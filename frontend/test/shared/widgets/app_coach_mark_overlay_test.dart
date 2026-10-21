import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_coach_mark_overlay.dart';

void main() {
  testWidgets('mostra titulo, passo e acoes', (tester) async {
    var nextCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: AppCoachMarkOverlay(
            title: 'Início',
            description: 'Explica a home.',
            stepIndex: 0,
            stepCount: 5,
            highlights: const [
              AppCoachMarkHighlight(rect: Rect.fromLTWH(40, 600, 64, 64)),
            ],
            onNext: () => nextCount++,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Explica a home.'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('Pular'), findsNothing);

    await tester.tap(find.text('Próximo'));
    await tester.pump();
    expect(nextCount, 1);
  });

  testWidgets('sem chrome nao mostra card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: AppCoachMarkOverlay(
            title: 'Início',
            description: 'Explica a home.',
            stepIndex: 0,
            stepCount: 5,
            showChrome: false,
            onNext: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Início'), findsNothing);
    expect(find.text('Próximo'), findsNothing);
  });
}
