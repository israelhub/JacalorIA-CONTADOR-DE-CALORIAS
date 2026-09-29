import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/food_analysis/helpers/food_review_helpers.dart';
import 'package:jacaloria/features/food_analysis/models/food_analysis_result.dart';
import 'package:jacaloria/features/food_analysis/models/food_meal_record.dart';
import 'package:jacaloria/features/food_analysis/pages/food_meal_details_page.dart';
import 'package:jacaloria/features/food_analysis/pages/food_review_page.dart';
import 'package:jacaloria/features/food_analysis/services/food_analysis_service.dart';
import 'package:jacaloria/features/home/services/meal_service.dart';

class _FakeFoodAnalysisService extends FoodAnalysisService {
  @override
  Future<FoodAnalysisResult> recalculate({
    required List<FoodAnalysisItem> items,
  }) async {
    return FoodAnalysisResult(
      items: items,
      totals: const FoodAnalysisTotals(
        calories: 410,
        protein: 22,
        carbs: 40,
        fat: 8,
      ),
      justification: 'ok',
    );
  }
}

class _FakeMealService extends MealService {
  @override
  Future<FoodMealRecord> updateMeal({
    required String mealId,
    required FoodMealRecord record,
    required FoodAnalysisResult analysis,
  }) async {
    return FoodMealRecord(
      id: mealId,
      imageBytes: null,
      imageAsset: record.imageAsset,
      imageUrl: record.imageUrl,
      createdAt: record.createdAt,
      title: record.title,
      description: record.description,
      kcalLabel: '${analysis.totals.calories.round()} kcal',
      timeLabel: record.timeLabel,
      mealType: record.mealType,
      calories: analysis.totals.calories.round(),
      protein: analysis.totals.protein.round(),
      carbs: analysis.totals.carbs.round(),
      fat: analysis.totals.fat.round(),
      items: analysis.items,
    );
  }
}

Widget _wrap(Widget child) => MaterialApp(home: child);

FoodMealRecord _mealFixture() {
  return FoodMealRecord(
    id: 'meal-1',
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
    createdAt: DateTime(2026, 7, 22, 12, 55),
    items: const [
      FoodAnalysisItem(
        name: 'Arroz',
        grams: 100,
        calories: 130,
        protein: 3,
        carbs: 28,
        fat: 0.2,
        source: 'taco_db',
        matchedFood: 'Arroz, tipo 1, cozido',
      ),
      FoodAnalysisItem(
        name: 'Feijao preto cozido',
        grams: 80,
        calories: 95,
        protein: 6,
        carbs: 16,
        fat: 0.5,
        source: 'ai_estimate',
      ),
    ],
  );
}

void main() {
  testWidgets('renderiza detalhes da refeicao com macros e itens', (
    tester,
  ) async {
    final record = _mealFixture();

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
    expect(find.text('Arroz'), findsOneWidget);
    expect(find.text('Feijao preto cozido'), findsOneWidget);
    expect(find.textContaining('56/200g'), findsOneWidget);
    expect(find.textContaining('13/120g'), findsOneWidget);
    expect(find.textContaining('1/60g'), findsOneWidget);
  });

  testWidgets('mostra tag TACO, match expandido e barras vs total da refeicao', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        FoodMealDetailsPage(
          record: _mealFixture(),
          userProfile: const {
            'dailyProteinGoal': 120,
            'dailyCarbsGoal': 200,
            'dailyFatGoal': 60,
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TACO'), findsOneWidget);
    expect(
      find.text('Identificado na tabela TACO como: Arroz, tipo 1, cozido'),
      findsNothing,
    );
    expect(find.text('3/13g'), findsNothing);
    expect(find.text('28/56g'), findsNothing);
    expect(find.text('13/120g'), findsOneWidget);

    await tester.ensureVisible(find.text('Arroz'));
    await tester.tap(find.text('Arroz'));
    await tester.pumpAndSettle();

    expect(
      find.text('Identificado na tabela TACO como: Arroz, tipo 1, cozido'),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('130kcal')).dy,
      lessThan(
        tester
            .getTopLeft(
              find.text(
                'Identificado na tabela TACO como: Arroz, tipo 1, cozido',
              ),
            )
            .dy,
      ),
    );
    expect(
      tester.getTopLeft(find.text('130kcal')).dy,
      lessThan(tester.getTopLeft(find.text('Carboidratos').last).dy),
    );
    expect(find.text('3/13g'), findsOneWidget);
    expect(find.text('28/56g'), findsOneWidget);
    expect(find.text('3/120g'), findsNothing);

    await tester.tap(find.text('Feijao preto cozido'));
    await tester.pumpAndSettle();

    expect(find.text('TACO'), findsOneWidget);
    expect(find.text('6/13g'), findsOneWidget);
  });

  testWidgets('atualiza detalhes apos editar e confirmar refeicao', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        FoodMealDetailsPage(
          record: _mealFixture(),
          userProfile: const {
            'dailyProteinGoal': 120,
            'dailyCarbsGoal': 200,
            'dailyFatGoal': 60,
          },
          mealService: _FakeMealService(),
          analysisService: _FakeFoodAnalysisService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar refeição'));
    await tester.pumpAndSettle();

    expect(find.byType(FoodReviewPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('food-review-meal-title-text')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('food-review-meal-title-field')),
      'Janta leve',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('food-review-meal-type-dinner')));
    await tester.pump();

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.byType(FoodReviewPage), findsNothing);
    expect(find.byType(FoodMealDetailsPage), findsOneWidget);
    expect(find.text('Janta leve'), findsOneWidget);
    expect(find.text('Janta'), findsOneWidget);
    expect(find.textContaining('410 Calorias consumidas'), findsOneWidget);
  });

  testWidgets('modo somente leitura oculta editar, excluir e salvar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        FoodMealDetailsPage(
          record: _mealFixture(),
          readOnly: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Detalhes da refeição'), findsOneWidget);
    expect(find.text('Arroz'), findsOneWidget);
    expect(find.byTooltip('Editar refeição'), findsNothing);
    expect(find.byTooltip('Excluir refeição'), findsNothing);
    expect(find.byTooltip('Salvar para reutilizar'), findsNothing);
  });
}
