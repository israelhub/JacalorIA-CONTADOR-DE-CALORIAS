import assert from 'node:assert/strict';
import {
  computeGoalAverageCalories,
  computeGoalDeviation,
  countInclusiveCalendarDays,
} from './goal-average.util';

const msPerDay = 24 * 60 * 60 * 1000;

// Exemplo do produto: dia 1 = 1869; dia 2 = 1900 → média 1884.5
assert.equal(computeGoalAverageCalories(1869, 1), 1869);
assert.equal(computeGoalAverageCalories(1869 + 1900, 2), 1884.5);
assert.equal(computeGoalDeviation(1884.5, 1882), 2.5);

// Virada de dia: 3 midnights inclusivos (20, 21, 22)
const day20 = Date.UTC(2026, 6, 20);
const day22 = Date.UTC(2026, 6, 22);
assert.equal(countInclusiveCalendarDays(day20, day22), 3);
assert.equal(countInclusiveCalendarDays(day20, day20), 1);
assert.equal(countInclusiveCalendarDays(day20, day20 + msPerDay), 2);

// Dia sem refeição conta como 0 no numerador
assert.equal(computeGoalAverageCalories(5608, 3), 1869.3);

console.log('goal-average.util ok');
