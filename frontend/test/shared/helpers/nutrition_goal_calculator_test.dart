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
      expect(result.dailyProteinGoal, 124);
      expect(result.dailyCarbsGoal, 224);
      expect(result.dailyFatGoal, 65);
    });

    test('perder peso cruzando IMC 30 não dispara a meta para cima', () {
      NutritionGoalResult goalAt(double weight) {
        return calculateNutritionGoals(
          NutritionGoalInput(
            weight: weight,
            height: 170,
            age: 52,
            sex: 'Feminino',
            objective: 'loseWeight',
            activityLevel: 'moderate',
          ),
        );
      }

      final previous = goalAt(87.8);
      final current = goalAt(86.2);

      expect(current.dailyCalorieGoal, lessThanOrEqualTo(previous.dailyCalorieGoal + 20));
      expect(current.dailyCalorieGoal, inInclusiveRange(1550, 1700));

      final justAbove30 = goalAt(86.7);
      final justBelow30 = goalAt(86.6);
      expect(
        (justAbove30.dailyCalorieGoal - justBelow30.dailyCalorieGoal).abs(),
        lessThanOrEqualTo(15),
      );
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
