enum HomeObjective { loseWeight, gainMass, maintainWeight }

/// Emoção do mascote conforme a situação atual da meta do dia.
enum HomeMascotEmotion { idle, sad, scared, happy }

/// Emagrecer: meta bate entre (meta - 200) e a meta.
const int loseWeightBelowToleranceKcal = 200;

/// Manter peso: faixa de ±100 kcal em torno da meta.
const int maintainWeightToleranceKcal = 100;

HomeObjective readHomeObjective(Map<String, dynamic>? profile) {
  final objectiveValue =
      profile?['objective'] as String? ?? profile?['objective_type'] as String?;

  switch (objectiveValue) {
    case 'loseWeight':
      return HomeObjective.loseWeight;
    case 'gainMass':
      return HomeObjective.gainMass;
    default:
      return HomeObjective.maintainWeight;
  }
}

bool hasReachedCalorieGoalForObjective({
  required int consumedCalories,
  required int goalCalories,
  required HomeObjective objective,
}) {
  if (goalCalories <= 0) {
    return false;
  }

  switch (objective) {
    case HomeObjective.loseWeight:
      final minCalories = goalCalories - loseWeightBelowToleranceKcal;
      return consumedCalories >= minCalories &&
          consumedCalories <= goalCalories;
    case HomeObjective.gainMass:
      return consumedCalories > goalCalories;
    case HomeObjective.maintainWeight:
      return consumedCalories >= goalCalories - maintainWeightToleranceKcal &&
          consumedCalories <= goalCalories + maintainWeightToleranceKcal;
  }
}

bool hasReachedCalorieGoalForProfile({
  required int consumedCalories,
  required int goalCalories,
  required Map<String, dynamic>? userProfile,
}) {
  return hasReachedCalorieGoalForObjective(
    consumedCalories: consumedCalories,
    goalCalories: goalCalories,
    objective: readHomeObjective(userProfile),
  );
}

bool isCalorieGoalExceededForObjective({
  required int consumedCalories,
  required int goalCalories,
  required HomeObjective objective,
}) {
  switch (objective) {
    case HomeObjective.gainMass:
      // Ultrapassar a meta é o objetivo — nunca é "excesso ruim".
      return false;
    case HomeObjective.maintainWeight:
      return consumedCalories > goalCalories + maintainWeightToleranceKcal;
    case HomeObjective.loseWeight:
      return consumedCalories > goalCalories;
  }
}

bool isCalorieGoalExceededForProfile({
  required int consumedCalories,
  required int goalCalories,
  required Map<String, dynamic>? userProfile,
}) {
  return isCalorieGoalExceededForObjective(
    consumedCalories: consumedCalories,
    goalCalories: goalCalories,
    objective: readHomeObjective(userProfile),
  );
}

/// Resolve a emoção do Jaca com base na situação atual da meta.
///
/// - Sem refeições: triste
/// - Fora da meta para cima de forma ruim (emagrecer / manter): assustado
/// - Meta batida (inclui ganhar massa acima da meta): feliz
/// - Ainda no caminho: padrão
HomeMascotEmotion resolveHomeMascotEmotion({
  required int consumedCalories,
  required int goalCalories,
  required HomeObjective objective,
  required bool hasMeals,
  bool isFirstHomeAccess = false,
}) {
  if (!hasMeals && !isFirstHomeAccess) {
    return HomeMascotEmotion.sad;
  }

  if (isCalorieGoalExceededForObjective(
    consumedCalories: consumedCalories,
    goalCalories: goalCalories,
    objective: objective,
  )) {
    return HomeMascotEmotion.scared;
  }

  if (hasReachedCalorieGoalForObjective(
    consumedCalories: consumedCalories,
    goalCalories: goalCalories,
    objective: objective,
  )) {
    return HomeMascotEmotion.happy;
  }

  return HomeMascotEmotion.idle;
}

HomeMascotEmotion resolveHomeMascotEmotionForProfile({
  required int consumedCalories,
  required int goalCalories,
  required Map<String, dynamic>? userProfile,
  required bool hasMeals,
  bool isFirstHomeAccess = false,
}) {
  return resolveHomeMascotEmotion(
    consumedCalories: consumedCalories,
    goalCalories: goalCalories,
    objective: readHomeObjective(userProfile),
    hasMeals: hasMeals,
    isFirstHomeAccess: isFirstHomeAccess,
  );
}

/// Texto curto no card da home explicando como bater o objetivo do dia.
String calorieGoalExplanationForObjective(HomeObjective objective) {
  switch (objective) {
    case HomeObjective.loseWeight:
      return 'Seu objetivo é atingir a meta diária de calorias ou ficar até '
          '$loseWeightBelowToleranceKcal calorias abaixo dela, '
          'sem poder ultrapassá-la.';
    case HomeObjective.gainMass:
      return 'Seu objetivo é registrar acima da sua meta diária de calorias.';
    case HomeObjective.maintainWeight:
      return 'Seu objetivo é ficar até $maintainWeightToleranceKcal calorias '
          'acima ou abaixo da meta.';
  }
}

String calorieGoalExplanationForProfile(Map<String, dynamic>? userProfile) {
  return calorieGoalExplanationForObjective(readHomeObjective(userProfile));
}
