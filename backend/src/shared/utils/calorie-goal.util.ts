type Objective = 'loseWeight' | 'gainMass' | 'maintainWeight';

export function normalizeObjective(value?: string | null): Objective {
  switch (value) {
    case 'loseWeight':
    case 'gainMass':
      return value;
    default:
      return 'maintainWeight';
  }
}

export function hasReachedCalorieGoal(params: {
  consumedCalories: number;
  dailyCalorieGoal: number;
  objective?: string | null;
}): boolean {
  const { consumedCalories, dailyCalorieGoal, objective } = params;

  if (dailyCalorieGoal <= 0) {
    return false;
  }

  const normalizedObjective = normalizeObjective(objective);
  if (normalizedObjective === 'loseWeight') {
    return consumedCalories >= dailyCalorieGoal * 0.8 &&
      consumedCalories <= dailyCalorieGoal;
  }

  return consumedCalories >= dailyCalorieGoal;
}

export function isCalorieGoalExceeded(params: {
  consumedCalories: number;
  dailyCalorieGoal: number;
  objective?: string | null;
}): boolean {
  const { consumedCalories, dailyCalorieGoal, objective } = params;
  const normalizedObjective = normalizeObjective(objective);

  if (normalizedObjective !== 'loseWeight') {
    return false;
  }

  return consumedCalories > dailyCalorieGoal;
}
