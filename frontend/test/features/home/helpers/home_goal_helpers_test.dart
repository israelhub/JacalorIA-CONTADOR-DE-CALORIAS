import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/home/helpers/home_goal_helpers.dart';

void main() {
  group('hasReachedCalorieGoalForObjective', () {
    test('emagrecer bate a meta no limite ou ate 200 abaixo', () {
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 1800,
          goalCalories: 2000,
          objective: HomeObjective.loseWeight,
        ),
        isTrue,
      );
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 2000,
          goalCalories: 2000,
          objective: HomeObjective.loseWeight,
        ),
        isTrue,
      );
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 1799,
          goalCalories: 2000,
          objective: HomeObjective.loseWeight,
        ),
        isFalse,
      );
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 2001,
          goalCalories: 2000,
          objective: HomeObjective.loseWeight,
        ),
        isFalse,
      );
    });

    test('engordar bate a meta apenas acima do limite', () {
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 2001,
          goalCalories: 2000,
          objective: HomeObjective.gainMass,
        ),
        isTrue,
      );
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 2000,
          goalCalories: 2000,
          objective: HomeObjective.gainMass,
        ),
        isFalse,
      );
    });

    test('manter peso aceita diferenca de ate 100 acima ou abaixo', () {
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 1900,
          goalCalories: 2000,
          objective: HomeObjective.maintainWeight,
        ),
        isTrue,
      );
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 2100,
          goalCalories: 2000,
          objective: HomeObjective.maintainWeight,
        ),
        isTrue,
      );
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 1899,
          goalCalories: 2000,
          objective: HomeObjective.maintainWeight,
        ),
        isFalse,
      );
      expect(
        hasReachedCalorieGoalForObjective(
          consumedCalories: 2101,
          goalCalories: 2000,
          objective: HomeObjective.maintainWeight,
        ),
        isFalse,
      );
    });
  });

  group('isCalorieGoalExceededForObjective', () {
    test('emagrecer marca excedente acima da meta', () {
      expect(
        isCalorieGoalExceededForObjective(
          consumedCalories: 2001,
          goalCalories: 2000,
          objective: HomeObjective.loseWeight,
        ),
        isTrue,
      );
    });

    test('engordar nunca marca excedente', () {
      expect(
        isCalorieGoalExceededForObjective(
          consumedCalories: 3000,
          goalCalories: 2000,
          objective: HomeObjective.gainMass,
        ),
        isFalse,
      );
    });

    test('manter peso marca excedente acima da faixa de 100', () {
      expect(
        isCalorieGoalExceededForObjective(
          consumedCalories: 2100,
          goalCalories: 2000,
          objective: HomeObjective.maintainWeight,
        ),
        isFalse,
      );
      expect(
        isCalorieGoalExceededForObjective(
          consumedCalories: 2101,
          goalCalories: 2000,
          objective: HomeObjective.maintainWeight,
        ),
        isTrue,
      );
    });
  });

  group('calorieGoalExplanationForObjective', () {
    test('retorna texto conforme o objetivo', () {
      expect(
        calorieGoalExplanationForObjective(HomeObjective.loseWeight),
        'Seu objetivo é atingir a meta diária de calorias ou ficar até '
        '200 calorias abaixo dela, sem poder ultrapassá-la.',
      );
      expect(
        calorieGoalExplanationForObjective(HomeObjective.gainMass),
        'Seu objetivo é registrar acima da sua meta diária de calorias.',
      );
      expect(
        calorieGoalExplanationForObjective(HomeObjective.maintainWeight),
        'Seu objetivo é ficar até 100 calorias acima ou abaixo da meta.',
      );
    });
  });

  group('resolveHomeMascotEmotion', () {
    test('sem refeicoes fica triste', () {
      expect(
        resolveHomeMascotEmotion(
          consumedCalories: 0,
          goalCalories: 2000,
          objective: HomeObjective.loseWeight,
          hasMeals: false,
        ),
        HomeMascotEmotion.sad,
      );
    });

    test('emagrecer acima da meta fica assustado', () {
      expect(
        resolveHomeMascotEmotion(
          consumedCalories: 2100,
          goalCalories: 2000,
          objective: HomeObjective.loseWeight,
          hasMeals: true,
        ),
        HomeMascotEmotion.scared,
      );
    });

    test('ganhar massa acima da meta fica feliz, nao assustado', () {
      expect(
        resolveHomeMascotEmotion(
          consumedCalories: 2100,
          goalCalories: 2000,
          objective: HomeObjective.gainMass,
          hasMeals: true,
        ),
        HomeMascotEmotion.happy,
      );
    });

    test('manter peso dentro da faixa fica feliz', () {
      expect(
        resolveHomeMascotEmotion(
          consumedCalories: 2050,
          goalCalories: 2000,
          objective: HomeObjective.maintainWeight,
          hasMeals: true,
        ),
        HomeMascotEmotion.happy,
      );
    });

    test('manter peso acima da faixa fica assustado', () {
      expect(
        resolveHomeMascotEmotion(
          consumedCalories: 2200,
          goalCalories: 2000,
          objective: HomeObjective.maintainWeight,
          hasMeals: true,
        ),
        HomeMascotEmotion.scared,
      );
    });

    test('ainda no caminho fica no padrao', () {
      expect(
        resolveHomeMascotEmotion(
          consumedCalories: 1200,
          goalCalories: 2000,
          objective: HomeObjective.gainMass,
          hasMeals: true,
        ),
        HomeMascotEmotion.idle,
      );
    });
  });
}
