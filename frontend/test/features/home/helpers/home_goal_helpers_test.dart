import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/helpers/home_goal_helpers.dart';

void main() {
  group('hasReachedCalorieGoalForObjective', () {
    test('emagrecer considera meta atingida com 80%', () {
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 1600,
          goalCalories: 2000,
          objective: HomeObjective.loseWeight,
        ),
        isTrue,
      );
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 1599,
          goalCalories: 2000,
          objective: HomeObjective.loseWeight,
        ),
        isFalse,
      );
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 2100,
          goalCalories: 2000,
          objective: HomeObjective.loseWeight,
        ),
        isFalse,
      );
    });

    test('engordar e manter exigem ao menos 100%', () {
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 2000,
          goalCalories: 2000,
          objective: HomeObjective.gainMass,
        ),
        isTrue,
      );
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 1999,
          goalCalories: 2000,
          objective: HomeObjective.maintainWeight,
        ),
        isFalse,
      );
    });
  });

  group('isCalorieGoalExceededForObjective', () {
    test('apenas emagrecer marca excedente', () {
      expect(
        isCalorieGoalExceededForObjective(
          consumedCalories: 2100,
          goalCalories: 2000,
          objective: HomeObjective.loseWeight,
        ),
        isTrue,
      );
      expect(
        isCalorieGoalExceededForObjective(
          consumedCalories: 2100,
          goalCalories: 2000,
          objective: HomeObjective.gainMass,
        ),
        isFalse,
      );
      expect(
        isCalorieGoalExceededForObjective(
          consumedCalories: 2100,
          goalCalories: 2000,
          objective: HomeObjective.maintainWeight,
        ),
        isFalse,
      );
    });
  });
}
