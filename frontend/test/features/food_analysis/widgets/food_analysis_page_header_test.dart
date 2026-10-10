import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/food_analysis/widgets/food_analysis_page_header.dart';
import 'package:jacaloria/shared/widgets/app_back_page_header.dart';

Widget _wrap(PreferredSizeWidget child) =>
    MaterialApp(home: Scaffold(appBar: child));

void main() {
  testWidgets('renderiza o header compartilhado transparente', (tester) async {
    await tester.pumpWidget(
      _wrap(const FoodAnalysisPageHeader(title: 'Nova refeição')),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(AppBackPageHeaderBar), findsOneWidget);
    expect(find.text('Nova refeição'), findsOneWidget);
  });
}
