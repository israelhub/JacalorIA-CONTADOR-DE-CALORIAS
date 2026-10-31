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

    test('Mifflin-St Jeor com peso real reduz a meta ao emagrecer', () {
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

      expect(goalAt(83.3).dailyCalorieGoal, 1785);
      expect(goalAt(83.0).dailyCalorieGoal, 1781);
      expect(goalAt(82.2).dailyCalorieGoal, 1768);
      expect(goalAt(82.2).effectiveWeightKg, closeTo(82.2, 0.01));

      expect(
        goalAt(86.2).dailyCalorieGoal,
        lessThan(goalAt(87.8).dailyCalorieGoal),
      );
      expect(
        (goalAt(86.7).dailyCalorieGoal - goalAt(86.6).dailyCalorieGoal).abs(),
        lessThanOrEqualTo(5),
      );
    });

    test('ganhar massa usa superávit de 1100 kcal (~1 kg/semana)', () {
      const input = NutritionGoalInput(
        weight: 82.2,
        height: 170,
        age: 52,
        sex: 'Feminino',
        activityLevel: 'moderate',
        objective: 'maintainWeight',
      );
      final maintain = calculateNutritionGoals(input);
      final gain = calculateNutritionGoals(
        NutritionGoalInput(
          weight: input.weight,
          height: input.height,
          age: input.age,
          sex: input.sex,
          activityLevel: input.activityLevel,
          objective: 'gainMass',
        ),
      );

      expect(gain.dailyCalorieGoal, maintain.dailyCalorieGoal + 1100);
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
