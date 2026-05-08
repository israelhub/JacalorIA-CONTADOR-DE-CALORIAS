enum HomeObjective { loseWeight, gainMass, maintainWeight }

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

  if (objective == HomeObjective.loseWeight) {
    return consumedCalories >= (goalCalories * 0.8) &&
        consumedCalories <= goalCalories;
  }

  return consumedCalories >= goalCalories;
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
  if (objective != HomeObjective.loseWeight) {
    return false;
  }

  return consumedCalories > goalCalories;
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
