import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/shared/theme/app_theme.dart';
import 'package:jacaloria/shared/widgets/app_guide_card.dart';

void main() {
  testWidgets('AppGuideCard usa texto claro por padrao', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppGuideCard(
            title: 'Treine com seus amigos',
            description: 'Descricao',
            icon: Icons.emoji_events_rounded,
            onClose: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final titleText = tester.widget<Text>(find.text('Treine com seus amigos'));
    final descriptionText = tester.widget<Text>(find.text('Descricao'));

    expect(titleText.style?.color, AppColors.surface);
    expect(descriptionText.style?.color, AppColors.surface);
  });
}