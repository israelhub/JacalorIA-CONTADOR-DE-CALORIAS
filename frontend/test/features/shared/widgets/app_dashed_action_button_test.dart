import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/shared/widgets/app_dashed_action_button.dart';

void main() {
  testWidgets('AppDashedActionButton dispara onTap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDashedActionButton(
            label: 'Criar novo grupo',
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Criar novo grupo'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}