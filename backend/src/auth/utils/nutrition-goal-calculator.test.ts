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

// Mifflin-St Jeor (peso real) + fator 1,55 − 500 kcal (AND/NIH).
assert.equal(goalAt(83.3), 1785);
assert.equal(goalAt(83.0), 1781);
assert.equal(goalAt(82.2), 1768);
assert.ok(
  goalAt(82.2) < goalAt(83.3),
  'perder peso deve reduzir a meta na Mifflin com peso real',
);

const previousGoal = goalAt(87.8);
const currentGoal = goalAt(86.2);
assert.ok(
  currentGoal < previousGoal,
  `perder peso não deveria subir a meta: ${previousGoal} → ${currentGoal}`,
);
assert.ok(
  Math.abs(goalAt(86.7) - goalAt(86.6)) <= 5,
  'meta deve ser contínua no IMC 30',
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
const obeseMaintain = calculateNutritionGoalsFromProfile({
  ...margareth,
  weight: 110,
  objective: 'maintainWeight',
});
assert.ok(obese && obeseMaintain);
assert.equal(obese.dailyCalorieGoal, obeseMaintain.dailyCalorieGoal - 500);

console.log(
  `nutrition-goal-calculator ok (83.3=${goalAt(83.3)}, 82.2=${goalAt(82.2)})`,
);
