import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/shared/widgets/macro_progress_indicator.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renderiza label, barra e contagem do macro', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const MacroProgressIndicator(
          label: 'Carboidratos',
          consumed: 10,
          goal: 120,
          color: Color(0xFF7CBF4D),
          progressKey: ValueKey('macro-progress-carboidratos'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Carboidratos'), findsOneWidget);
    expect(find.textContaining('10/120'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('macro-progress-carboidratos')),
      findsOneWidget,
    );
  });
}
