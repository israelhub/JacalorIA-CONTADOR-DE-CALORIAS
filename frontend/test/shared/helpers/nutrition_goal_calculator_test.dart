import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/shared/helpers/nutrition_goal_calculator.dart';

void main() {
  group('calculateNutritionGoals', () {
    test('converte unidades e calcula metas diárias', () {
      final result = calculateNutritionGoals(
        const NutritionGoalInput(
          weight: 154,
          height: 1.75,
          age: 30,
          sex: 'Masculino',
          objective: 'maintainWeight',
          activityLevel: 'sedentary',
          weightUnit: 'lb',
          heightUnit: 'm',
        ),
      );

      expect(result.effectiveWeightKg, closeTo(69.85, 0.01));
      expect(result.effectiveHeightCm, closeTo(175, 0.01));
      expect(result.dailyCalorieGoal, 1977);
      expect(result.dailyProteinGoal, 140);
      expect(result.dailyCarbsGoal, 197);
      expect(result.dailyFatGoal, 70);
    });
  });

  group('calculateAgeFromBirthDate', () {
    test('aceita data no formato ISO ou brasileiro', () {
      expect(
        calculateAgeFromBirthDate(
          '2000-01-01',
          referenceDate: DateTime(2030, 1, 1),
        ),
        30,
      );
      expect(
        calculateAgeFromBirthDate(
          '01/01/2000',
          referenceDate: DateTime(2030, 1, 1),
        ),
        30,
      );
    });
  });
}
