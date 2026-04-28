import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/food_analysis/models/food_analysis_result.dart';
import 'package:jacaloria/features/food_analysis/pages/food_meal_details_page.dart';
import 'package:jacaloria/features/food_analysis/pages/food_review_page.dart';
import 'package:jacaloria/features/food_analysis/services/food_analysis_service.dart';
import 'package:jacaloria/shared/widgets/app_button.dart';

class _FakeFoodAnalysisService extends FoodAnalysisService {
  _FakeFoodAnalysisService();

  List<FoodAnalysisItem>? lastItems;

  @override
  Future<FoodAnalysisResult> recalculate({
    required List<FoodAnalysisItem> items,
  }) async {
    lastItems = items;
    return FoodAnalysisResult(
      items: items,
      totals: const FoodAnalysisTotals(
        calories: 520,
        protein: 25,
        carbs: 62,
        fat: 12,
      ),
      justification: 'ok',
    );
  }
}

FoodAnalysisResult _analysisFixture() {
  return const FoodAnalysisResult(
    items: [
      FoodAnalysisItem(
        name: 'Arroz branco cozido',
        grams: 100,
        calories: 130,
        protein: 3,
        carbs: 28,
        fat: 0.2,
      ),
      FoodAnalysisItem(
        name: 'Feijão preto cozido',
        grams: 100,
        calories: 135,
        protein: 9,
        carbs: 24,
        fat: 0.5,
      ),
      FoodAnalysisItem(
        name: 'Tomate',
        grams: 100,
        calories: 18,
        protein: 1,
        carbs: 4,
        fat: 0.2,
      ),
    ],
    totals: FoodAnalysisTotals(calories: 283, protein: 13, carbs: 56, fat: 1),
    justification: 'A soma considera porções médias dos alimentos detectados.',
  );
}

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpFoodReview(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _wrap(
      FoodReviewPage(
        imageBytes: null,
        analysis: _analysisFixture(),
            analysisService: _FakeFoodAnalysisService(),
      ),
    ),
  );
}

void main() {
  group('FoodReviewPage', () {
    testWidgets('renderiza layout principal do design de revisão', (
      WidgetTester tester,
    ) async {
      await _pumpFoodReview(tester);
      await tester.pumpAndSettle();

      expect(find.text('Revisar análise'), findsOneWidget);
      expect(find.text('Alimentos identificados pela IA'), findsOneWidget);
      expect(find.text('Adicionar novo alimento'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
      expect(find.text('Estimativa nutricional do prato'), findsNothing);
      expect(find.text('Justificativa da estimativa'), findsNothing);
      expect(
        find.byKey(const ValueKey('food-review-main-divider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('food-review-confirm-button')),
        findsOneWidget,
      );
      expect(find.byType(AppButton), findsOneWidget);
      expect(
        find.byKey(const ValueKey('food-review-ai-title-inline')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('food-review-image-container')),
        findsOneWidget,
      );

      final firstUnitField = find.byKey(
        const ValueKey('food-review-quantity-unit-field-0'),
      );
      expect(firstUnitField, findsOneWidget);
      expect(find.text('g'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('food-review-quantity-unit-field-0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ml').last);
      await tester.pumpAndSettle();
      expect(find.text('ml'), findsOneWidget);
    });

    testWidgets('adiciona novo item ao tocar no botão tracejado', (
      WidgetTester tester,
    ) async {
      await _pumpFoodReview(tester);
      await tester.pumpAndSettle();

      expect(find.text('Novo alimento'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('food-review-add-item-button')),
      );
      await tester.pump();

      expect(find.text('Novo alimento'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('food-review-unit-field-3')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('food-review-quantity-unit-field-3')),
        findsOneWidget,
      );
    });

    testWidgets('remove item antes de salvar e recalcula com a lista atual', (
      WidgetTester tester,
    ) async {
      final service = _FakeFoodAnalysisService();

      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          FoodReviewPage(
            imageBytes: null,
            analysis: _analysisFixture(),
            analysisService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(service.lastItems, isNotNull);
      expect(service.lastItems, hasLength(2));
      expect(find.byType(FoodMealDetailsPage), findsOneWidget);
    });

    testWidgets('abre detalhes da refeicao ao confirmar sem alteracoes', (
      WidgetTester tester,
    ) async {
      await _pumpFoodReview(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.byType(FoodMealDetailsPage), findsOneWidget);
      expect(find.text('Detalhes da refeição'), findsOneWidget);
    });
  });
}
