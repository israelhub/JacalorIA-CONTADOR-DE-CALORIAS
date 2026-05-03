type Objective = 'loseWeight' | 'gainMass' | 'maintainWeight';

export type NutritionProfileInput = {
  birthDate?: string | null;
  weight?: number | string | null;
  height?: number | string | null;
  weightUnit?: string | null;
  heightUnit?: string | null;
  sex?: string | null;
  objective?: string | null;
  activityLevel?: string | null;
};

export type NutritionGoalOutput = {
  dailyCalorieGoal: number;
  dailyProteinGoal: number;
  dailyCarbsGoal: number;
  dailyFatGoal: number;
};

export function calculateNutritionGoalsFromProfile(
  input: NutritionProfileInput,
): NutritionGoalOutput | null {
  const weightKg = toKilograms(input.weight, input.weightUnit);
  const heightCm = toCentimeters(input.height, input.heightUnit);
  const age = calculateAgeFromBirthDate(input.birthDate);

  if (weightKg <= 0 || heightCm <= 0 || age <= 0) {
    return null;
  }

  const objective = normalizeObjective(input.objective);
  const bmi = calculateBmi(weightKg, heightCm);
  const metabolicWeightKg = resolveMetabolicWeightKg(weightKg, heightCm, objective);

  const sexFactor = resolveSexFactor(input.sex);
  const bmr = (10 * metabolicWeightKg) + (6.25 * heightCm) - (5 * age) + sexFactor;
  const activityMultiplier = resolveActivityMultiplier(input.activityLevel);
  const tdee = bmr * activityMultiplier;

  const adjustedCalories = applyObjectiveAdjustment(
    tdee,
    objective,
    bmi,
    input.activityLevel,
  );
  const minimumCalories = resolveCalorieFloor(input.sex);
  const dailyCalorieGoal = Math.max(minimumCalories, Math.round(adjustedCalories));

  const macros = resolveMacroGoals(
    dailyCalorieGoal,
    objective,
    metabolicWeightKg,
  );

  return {
    dailyCalorieGoal,
    dailyProteinGoal: macros.dailyProteinGoal,
    dailyCarbsGoal: macros.dailyCarbsGoal,
    dailyFatGoal: macros.dailyFatGoal,
  };
}

function calculateAgeFromBirthDate(value?: string | null): number {
  if (!value) {
    return 0;
  }

  const birthDate = new Date(value);
  if (Number.isNaN(birthDate.getTime())) {
    return 0;
  }

  const today = new Date();
  let age = today.getFullYear() - birthDate.getFullYear();
  const hadBirthday =
    today.getMonth() > birthDate.getMonth() ||
    (today.getMonth() === birthDate.getMonth() &&
      today.getDate() >= birthDate.getDate());

  if (!hadBirthday) {
    age -= 1;
  }

  return Math.max(0, Math.min(150, age));
}

function toKilograms(
  value: number | string | null | undefined,
  unit: string | null | undefined,
): number {
  const numeric = toNumber(value);
  if (numeric <= 0) {
    return 0;
  }

  switch ((unit ?? 'kg').toLowerCase()) {
    case 'lb':
      return numeric * 0.45359237;
    case 'g':
      return numeric / 1000;
    default:
      return numeric;
  }
}

function toCentimeters(
  value: number | string | null | undefined,
  unit: string | null | undefined,
): number {
  const numeric = toNumber(value);
  if (numeric <= 0) {
    return 0;
  }

  switch ((unit ?? 'cm').toLowerCase()) {
    case 'm':
      return numeric * 100;
    case 'ft':
      return numeric * 30.48;
    case 'in':
      return numeric * 2.54;
    default:
      return numeric;
  }
}

function calculateBmi(weightKg: number, heightCm: number): number {
  const heightM = heightCm / 100;
  if (heightM <= 0) {
    return 0;
  }

  return weightKg / (heightM * heightM);
}

function resolveActivityMultiplier(activityLevel?: string | null): number {
  switch ((activityLevel ?? 'sedentary').toLowerCase()) {
    case 'lightly':
      return 1.375;
    case 'moderate':
      return 1.55;
    case 'very':
      return 1.725;
    case 'extreme':
      return 1.9;
    default:
      return 1.2;
  }
}

function resolveSexFactor(sex?: string | null): number {
  switch ((sex ?? '').trim().toLowerCase()) {
    case 'feminino':
      return -161;
    case 'masculino':
      return 5;
    default:
      return -78;
  }
}

function resolveCalorieFloor(sex?: string | null): number {
  switch ((sex ?? '').trim().toLowerCase()) {
    case 'feminino':
      return 1200;
    case 'masculino':
      return 1500;
    default:
      return 1350;
  }
}

function normalizeObjective(objective?: string | null): Objective {
  switch (objective) {
    case 'loseWeight':
    case 'gainMass':
      return objective;
    default:
      return 'maintainWeight';
  }
}

function applyObjectiveAdjustment(
  tdee: number,
  objective: Objective,
  bmi: number,
  activityLevel?: string | null,
): number {
  if (objective === 'loseWeight') {
    const deficitPercent = resolveLossDeficitPercent(bmi, activityLevel);
    return tdee * (1 - deficitPercent);
  }

  if (objective === 'gainMass') {
    const surplusPercent = resolveGainSurplusPercent(bmi, activityLevel);
    return tdee * (1 + surplusPercent);
  }

  return tdee;
}

function resolveLossDeficitPercent(
  bmi: number,
  activityLevel?: string | null,
): number {
  let percent = 0.2;

  if (bmi >= 40) {
    percent = 0.3;
  } else if (bmi >= 35) {
    percent = 0.27;
  } else if (bmi >= 30) {
    percent = 0.25;
  } else if (bmi >= 27) {
    percent = 0.22;
  } else {
    percent = 0.18;
  }

  const normalizedActivity = (activityLevel ?? '').toLowerCase();
  if (normalizedActivity === 'very' || normalizedActivity === 'extreme') {
    percent -= 0.02;
  }

  return clamp(percent, 0.15, 0.3);
}

function resolveGainSurplusPercent(
  bmi: number,
  activityLevel?: string | null,
): number {
  let percent = 0.1;

  if (bmi < 18.5) {
    percent = 0.2;
  } else if (bmi < 22) {
    percent = 0.15;
  } else if (bmi < 25) {
    percent = 0.12;
  }

  const normalizedActivity = (activityLevel ?? '').toLowerCase();
  if (normalizedActivity === 'very' || normalizedActivity === 'extreme') {
    percent += 0.02;
  }

  return clamp(percent, 0.08, 0.22);
}

function resolveMetabolicWeightKg(
  weightKg: number,
  heightCm: number,
  objective: Objective,
): number {
  if (objective !== 'loseWeight') {
    return weightKg;
  }

  const heightM = heightCm / 100;
  if (heightM <= 0) {
    return weightKg;
  }

  const bmi = weightKg / (heightM * heightM);
  if (bmi < 30) {
    return weightKg;
  }

  const idealWeightKg = 24.9 * (heightM * heightM);
  const adjustedWeightKg = idealWeightKg + ((weightKg - idealWeightKg) * 0.25);
  return Math.max(idealWeightKg, Math.min(weightKg, adjustedWeightKg));
}

function resolveMacroGoals(
  dailyCalories: number,
  objective: Objective,
  metabolicWeightKg: number,
): {
  dailyProteinGoal: number;
  dailyFatGoal: number;
  dailyCarbsGoal: number;
} {
  const proteinPerKg = resolveProteinPerKg(objective);
  const fatPerKg = resolveFatPerKg(objective);

  const minProteinGrams = Math.round(metabolicWeightKg * proteinPerKg);
  const minFatGrams = Math.round(metabolicWeightKg * fatPerKg);

  const distribution = resolveMacroDistribution(objective);
  let proteinGrams = Math.round((dailyCalories * distribution.protein) / 4);
  let fatGrams = Math.round((dailyCalories * distribution.fat) / 9);

  proteinGrams = Math.max(proteinGrams, minProteinGrams);
  fatGrams = Math.max(fatGrams, minFatGrams);

  let carbsGrams = Math.max(
    0,
    Math.round((dailyCalories - (proteinGrams * 4) - (fatGrams * 9)) / 4),
  );

  const minCarbsGrams = Math.round(
    metabolicWeightKg * resolveCarbsPerKgFloor(objective),
  );

  if (carbsGrams < minCarbsGrams) {
    carbsGrams = minCarbsGrams;
  }

  const totalCalories = (proteinGrams * 4) + (fatGrams * 9) + (carbsGrams * 4);
  if (totalCalories > dailyCalories) {
    const overflow = totalCalories - dailyCalories;
    const fatReduction = Math.min(fatGrams - minFatGrams, Math.ceil(overflow / 9));
    fatGrams -= Math.max(0, fatReduction);
  }

  const recalculatedTotal = (proteinGrams * 4) + (fatGrams * 9);
  carbsGrams = Math.max(0, Math.round((dailyCalories - recalculatedTotal) / 4));

  return {
    dailyProteinGoal: proteinGrams,
    dailyFatGoal: fatGrams,
    dailyCarbsGoal: carbsGrams,
  };
}

function resolveProteinPerKg(objective: Objective): number {
  if (objective === 'loseWeight') {
    return 2.2;
  }

  if (objective === 'gainMass') {
    return 1.8;
  }

  return 1.6;
}

function resolveFatPerKg(objective: Objective): number {
  if (objective === 'loseWeight') {
    return 0.7;
  }

  return 0.8;
}

function resolveCarbsPerKgFloor(objective: Objective): number {
  if (objective === 'loseWeight') {
    return 1.5;
  }

  if (objective === 'gainMass') {
    return 2.5;
  }

  return 2;
}

function resolveMacroDistribution(objective: Objective): {
  protein: number;
  fat: number;
} {
  if (objective === 'loseWeight') {
    return { protein: 0.35, fat: 0.3 };
  }

  if (objective === 'gainMass') {
    return { protein: 0.25, fat: 0.25 };
  }

  return { protein: 0.25, fat: 0.3 };
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function toNumber(value: number | string | null | undefined): number {
  if (typeof value === 'number') {
    return Number.isFinite(value) ? value : 0;
  }

  if (typeof value === 'string') {
    const normalized = value.replace(',', '.').trim();
    const parsed = Number(normalized);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  return 0;
}
