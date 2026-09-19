import assert from 'node:assert/strict';
import { calculateNutritionGoalsFromProfile } from './nutrition-goal-calculator';

const margareth = {
  birthDate: '1974-06-13',
  height: 170,
  heightUnit: 'cm',
  weightUnit: 'kg',
  sex: 'Feminino',
  objective: 'loseWeight',
  activityLevel: 'moderate',
};

const goalAt = (weight: number) => {
  const result = calculateNutritionGoalsFromProfile({ ...margareth, weight });
  assert.ok(result, `meta deve calcular para ${weight} kg`);
  return result.dailyCalorieGoal;
};

const previousWeightKg = 87.8;
const currentWeightKg = 86.2;

const previousGoal = goalAt(previousWeightKg);
const currentGoal = goalAt(currentWeightKg);

// Bug original: 87,8 kg (IMC 30,4) → ~1628 kcal; 86,2 kg (IMC 29,8) → 1818 kcal.
assert.ok(
  currentGoal <= previousGoal + 20,
  `perder peso não deveria subir a meta: ${previousWeightKg} kg=${previousGoal}, ${currentWeightKg} kg=${currentGoal}`,
);
assert.ok(
  currentGoal >= 1550 && currentGoal <= 1700,
  `meta após 86,2 kg deveria ficar perto da anterior, veio ${currentGoal}`,
);

const justAbove30 = goalAt(86.7);
const justBelow30 = goalAt(86.6);
assert.ok(
  Math.abs(justAbove30 - justBelow30) <= 15,
  `meta deve ser contínua no IMC 30: 86,7=${justAbove30}, 86,6=${justBelow30}`,
);

const maintain = calculateNutritionGoalsFromProfile({
  birthDate: '1996-01-01',
  weight: 154,
  height: 1.75,
  weightUnit: 'lb',
  heightUnit: 'm',
  sex: 'Masculino',
  objective: 'maintainWeight',
  activityLevel: 'sedentary',
});
assert.ok(maintain);
assert.equal(maintain.dailyCalorieGoal, 1977);

const obese = calculateNutritionGoalsFromProfile({
  ...margareth,
  weight: 110,
});
const obeseActualWeight = calculateNutritionGoalsFromProfile({
  ...margareth,
  weight: 110,
  objective: 'maintainWeight',
});
assert.ok(obese && obeseActualWeight);
assert.ok(
  obese.dailyCalorieGoal < obeseActualWeight.dailyCalorieGoal,
  'IMC alto em emagrecimento ainda deve usar peso ajustado',
);

console.log(
  `nutrition-goal-calculator ok (87.8=${previousGoal}, 86.2=${currentGoal})`,
);
