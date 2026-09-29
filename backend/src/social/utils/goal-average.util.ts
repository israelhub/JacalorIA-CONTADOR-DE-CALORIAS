/**
 * Helpers puros da competição "Média de meta" (goal_average).
 * média = total de calorias no período ÷ dias civis decorridos do grupo.
 */

export function computeGoalAverageCalories(
  totalCalories: number,
  elapsedDays: number,
): number {
  if (!Number.isFinite(totalCalories) || !Number.isFinite(elapsedDays) || elapsedDays <= 0) {
    return 0;
  }
  return Math.round((totalCalories / elapsedDays) * 10) / 10;
}

export function computeGoalDeviation(averageCalories: number, dailyGoal: number): number {
  return Math.round(Math.abs(averageCalories - dailyGoal) * 10) / 10;
}

/** Dias civis inclusivos entre dois midnights (UTC ms de getDayStartInAppTimeZone). */
export function countInclusiveCalendarDays(startDayMs: number, endDayMs: number): number {
  if (!Number.isFinite(startDayMs) || !Number.isFinite(endDayMs) || endDayMs < startDayMs) {
    return 0;
  }
  const msPerDay = 24 * 60 * 60 * 1000;
  return Math.floor((endDayMs - startDayMs) / msPerDay) + 1;
}
