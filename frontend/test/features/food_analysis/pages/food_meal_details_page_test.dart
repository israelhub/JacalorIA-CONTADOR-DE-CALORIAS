import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/food_analysis/helpers/food_review_helpers.dart';
import 'package:jacaloria/features/food_analysis/models/food_analysis_result.dart';
import 'package:jacaloria/features/food_analysis/models/food_meal_record.dart';
import 'package:jacaloria/features/food_analysis/pages/food_meal_details_page.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('renderiza detalhes da refeicao com macros e itens', (
    tester,
  ) async {
    final record = FoodMealRecord(
      imageBytes: null,
      imageAsset: 'assets/images/smiling green cartoon crocodile@2x.webp',
      title: 'Almoço',
      description: 'Arroz, feijao e frango',
      kcalLabel: '283 kcal',
      timeLabel: '12:55',
      mealType: FoodMealType.lunch,
      calories: 283,
      protein: 13,
      carbs: 56,
      fat: 1,
      items: const [
        FoodAnalysisItem(
          name: 'Arroz branco cozido',
          grams: 100,
          calories: 130,
          protein: 3,
          carbs: 28,
          fat: 0.2,
        ),
        FoodAnalysisItem(
          name: 'Feijao preto cozido',
          grams: 80,
          calories: 95,
          protein: 6,
          carbs: 16,
          fat: 0.5,
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        FoodMealDetailsPage(
          record: record,
          userProfile: const {
            'dailyProteinGoal': 120,
            'dailyCarbsGoal': 200,
            'dailyFatGoal': 60,
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Detalhes da refeição'), findsOneWidget);
    expect(find.text('Almoço'), findsWidgets);
    expect(find.text('12:55'), findsOneWidget);
    expect(find.text('Arroz branco cozido'), findsOneWidget);
    expect(find.text('Feijao preto cozido'), findsOneWidget);
    expect(find.textContaining('56/200g'), findsOneWidget);
    expect(find.textContaining('13/120g'), findsOneWidget);
    expect(find.textContaining('1/60g'), findsOneWidget);
  });
}
