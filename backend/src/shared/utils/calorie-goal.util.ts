type Objective = 'loseWeight' | 'gainMass' | 'maintainWeight';

/** Emagrecer: meta bate entre (meta - 200) e a meta. */
export const LOSE_WEIGHT_BELOW_TOLERANCE_KCAL = 200;

/** Manter peso: faixa de ±100 kcal em torno da meta. */
export const MAINTAIN_WEIGHT_TOLERANCE_KCAL = 100;

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
    const minCalories = dailyCalorieGoal - LOSE_WEIGHT_BELOW_TOLERANCE_KCAL;
    return (
      consumedCalories >= minCalories && consumedCalories <= dailyCalorieGoal
    );
  }

  if (normalizedObjective === 'gainMass') {
    return consumedCalories > dailyCalorieGoal;
  }

  // maintainWeight: até 100 kcal acima ou abaixo
  return (
    consumedCalories >= dailyCalorieGoal - MAINTAIN_WEIGHT_TOLERANCE_KCAL &&
    consumedCalories <= dailyCalorieGoal + MAINTAIN_WEIGHT_TOLERANCE_KCAL
  );
}

export function isCalorieGoalExceeded(params: {
  consumedCalories: number;
  dailyCalorieGoal: number;
  objective?: string | null;
}): boolean {
  const { consumedCalories, dailyCalorieGoal, objective } = params;
  const normalizedObjective = normalizeObjective(objective);

  if (normalizedObjective === 'gainMass') {
    return false;
  }

  if (normalizedObjective === 'maintainWeight') {
    return consumedCalories > dailyCalorieGoal + MAINTAIN_WEIGHT_TOLERANCE_KCAL;
  }

  // loseWeight: não pode ultrapassar a meta
  return consumedCalories > dailyCalorieGoal;
}
