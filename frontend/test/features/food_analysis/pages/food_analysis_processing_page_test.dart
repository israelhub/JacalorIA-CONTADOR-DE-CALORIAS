import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/food_analysis/models/food_analysis_result.dart';
import 'package:jacaloria/features/food_analysis/pages/food_analysis_processing_page.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('mostra a tela intermediaria de analise', (tester) async {
    final completer = Completer<FoodAnalysisResult>();

    await tester.pumpWidget(
      _wrap(
        FoodAnalysisProcessingPage(
          imageBytes: null,
          title: 'Analisando...',
          message: 'A inteligência artificial está analisando a sua refeição...',
          operation: () => completer.future,
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Nova refeição'), findsOneWidget);
    expect(find.text('Analisando...'), findsOneWidget);
    expect(find.text('A inteligência artificial está analisando a sua refeição...'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}
