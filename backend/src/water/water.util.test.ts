import assert from 'node:assert/strict';
import {
  DEFAULT_DAILY_WATER_GOAL_ML,
  resolveDailyWaterGoalMl,
  shiftDateOnly,
} from './water.util';

assert.equal(resolveDailyWaterGoalMl(null), DEFAULT_DAILY_WATER_GOAL_ML);
assert.equal(resolveDailyWaterGoalMl(0), DEFAULT_DAILY_WATER_GOAL_ML);
assert.equal(resolveDailyWaterGoalMl(70), 2450);
assert.equal(resolveDailyWaterGoalMl(40), 1500);
assert.equal(resolveDailyWaterGoalMl(140), 4000);
assert.equal(shiftDateOnly('2026-09-27', -6), '2026-09-21');
assert.equal(shiftDateOnly('2026-03-01', -1), '2026-02-28');
