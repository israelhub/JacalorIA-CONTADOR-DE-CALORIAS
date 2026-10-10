import { parseNumber } from '../shared/utils/number-parser.util';
import { toDateOnly } from '../workouts/workout-import.util';

export const DEFAULT_DAILY_WATER_GOAL_ML = 2000;
export const WATER_ML_PER_KG = 35;
export const MIN_DAILY_WATER_GOAL_ML = 1500;
export const MAX_DAILY_WATER_GOAL_ML = 4000;
export const MAX_DAILY_WATER_ML = 8000;

export const resolveDailyWaterGoalMl = (weightKg: unknown): number => {
  const weight = parseNumber(weightKg, 0);
  if (!Number.isFinite(weight) || weight <= 0) {
    return DEFAULT_DAILY_WATER_GOAL_ML;
  }
  const raw = Math.round(weight * WATER_ML_PER_KG);
  return Math.min(MAX_DAILY_WATER_GOAL_ML, Math.max(MIN_DAILY_WATER_GOAL_ML, raw));
};

export const toDateOnlyOrToday = (value: unknown): string => {
  return toDateOnly(value, new Date().getFullYear()) ?? new Date().toISOString().slice(0, 10);
};

export const shiftDateOnly = (dateOnly: string, days: number): string => {
  const [year, month, day] = dateOnly.split('-').map(Number);
  const next = new Date(Date.UTC(year, month - 1, day + days));
  return next.toISOString().slice(0, 10);
};
