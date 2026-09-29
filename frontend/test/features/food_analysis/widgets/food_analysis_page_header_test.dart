import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/food_analysis/widgets/food_analysis_page_header.dart';
import 'package:jacaloria/shared/theme/app_theme.dart';

Widget _wrap(PreferredSizeWidget child) =>
    MaterialApp(home: Scaffold(appBar: child));

void main() {
  testWidgets('renderiza o header compartilhado com surface', (tester) async {
    await tester.pumpWidget(
      _wrap(const FoodAnalysisPageHeader(title: 'Nova refeição')),
    );

    await tester.pumpAndSettle();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));

    expect(appBar.backgroundColor, equals(AppColors.surface));
    expect(find.text('Nova refeição'), findsOneWidget);
  });
}
