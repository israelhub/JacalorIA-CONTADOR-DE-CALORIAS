import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/food_analysis/models/food_analysis_result.dart';
import 'package:jacaloria/features/food_analysis/models/food_meal_record.dart';

void main() {
  test('fromJson preserva os itens da refeição', () {
    final record = FoodMealRecord.fromJson({
      'title': 'Arroz branco cozido',
      'description': 'Arroz branco cozido, Feijão preto cozido',
      'calories': 283,
      'protein': 13,
      'carbs': 56,
      'fat': 1,
      'timeLabel': '12:55',
      'imageUrl': null,
      'analysisItems': [
        {
          'name': 'Arroz branco cozido',
          'grams': 100,
          'calories': 130,
          'unit': 'g',
          'protein': 3,
          'carbs': 28,
          'fat': 0.2,
        },
      ],
    });

    expect(record.items, hasLength(1));
    expect(record.items.first.name, 'Arroz branco cozido');
    expect(record.items.first.grams, 100);
  });

  test('fromAnalysis replica os itens da analise', () {
    const analysis = FoodAnalysisResult(
      items: [
        FoodAnalysisItem(
          name: 'Tomate',
          grams: 100,
          calories: 18,
          protein: 1,
          carbs: 4,
          fat: 0.2,
        ),
      ],
      totals: FoodAnalysisTotals(calories: 18, protein: 1, carbs: 4, fat: 0.2),
      justification: 'ok',
    );

    final record = FoodMealRecord.fromAnalysis(
      imageBytes: null,
      analysis: analysis,
      recordedAt: DateTime(2026, 4, 24, 12, 55),
    );

    expect(record.items, hasLength(1));
    expect(record.items.first.name, 'Tomate');
  });
}