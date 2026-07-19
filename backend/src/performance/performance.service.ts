import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { User } from '../auth/models/user.model';
import { Meal, MealStatus } from '../meals/models/meal.model';
import { GetWeightHistoryDto } from './dto/get-weight-history.dto';
import { UserWeightEntry } from './models/user-weight-entry.model';
import { StreakService } from '../streak/streak.service';
import { parseNumber } from '../shared/utils/number-parser.util';
import { hasReachedCalorieGoal } from '../shared/utils/calorie-goal.util';

type DayStatus = 'goal_achieved' | 'meal_registered' | 'no_record' | 'streak_blocker_applied';

type DailyTotals = {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
};

type CalendarDay = {
  day: number;
  status: DayStatus;
};

const FALLBACK_TIME_ZONE = 'America/Sao_Paulo';

@Injectable()
export class PerformanceService {
  private readonly appTimeZone = this.resolveAppTimeZone();

  constructor(
    @InjectModel(Meal)
    private readonly mealModel: typeof Meal,
    @InjectModel(User)
    private readonly userModel: typeof User,
    @InjectModel(UserWeightEntry)
    private readonly userWeightEntryModel: typeof UserWeightEntry,
    private readonly streakService: StreakService,
  ) {}

  async getMonthlyPerformance(userId: string, month?: string) {
    const { year, monthIndex } = this.parseMonth(month);
    const monthStart = new Date(Date.UTC(year, monthIndex, 1) - (24 * 60 * 60 * 1000));
    const monthEnd = new Date(
      Date.UTC(year, monthIndex + 1, 1) + (24 * 60 * 60 * 1000),
    );
    const daysInMonth = new Date(year, monthIndex + 1, 0).getDate();

    const [user, meals, monthWeightEntries, baselineEntry, latestMonthEntry] = await Promise.all([
      this.userModel.findByPk(userId, {
        attributes: [
          'dailyCalorieGoal',
          'dailyProteinGoal',
          'dailyCarbsGoal',
          'dailyFatGoal',
          'objective',
          'weight',
        ],
      }),
      this.mealModel.findAll({
        where: {
          userId,
          status: MealStatus.Active,
          createdAt: {
            [Op.gte]: monthStart,
            [Op.lt]: monthEnd,
          },
        },
        attributes: ['createdAt', 'calories', 'protein', 'carbs', 'fat'],
      }),
      this.userWeightEntryModel.findAll({
        where: {
          userId,
          recordedAt: {
            [Op.gte]: monthStart,
            [Op.lt]: monthEnd,
          },
        },
        order: [['recordedAt', 'ASC']],
        attributes: ['weight', 'recordedAt'],
      }),
      this.userWeightEntryModel.findOne({
        where: {
          userId,
          recordedAt: {
            [Op.lte]: monthStart,
          },
        },
        order: [['recordedAt', 'DESC']],
        attributes: ['weight', 'recordedAt'],
      }),
      this.userWeightEntryModel.findOne({
        where: {
          userId,
          recordedAt: {
            [Op.lt]: monthEnd,
          },
        },
        order: [['recordedAt', 'DESC']],
        attributes: ['weight', 'recordedAt'],
      }),
    ]);

    const calorieGoal = parseNumber(user?.dailyCalorieGoal, 2000);
    const proteinGoal = parseNumber(user?.dailyProteinGoal, 120);
    const carbsGoal = parseNumber(user?.dailyCarbsGoal, 200);
    const fatGoal = parseNumber(user?.dailyFatGoal, 60);

    const byDay = new Map<number, DailyTotals>();

    for (const meal of meals) {
      const date = new Date(meal.createdAt);
      const mealDateParts = this.getDatePartsInAppTimeZone(date);
      if (
        mealDateParts.year !== year ||
        mealDateParts.month !== monthIndex + 1
      ) {
        continue;
      }

      const day = mealDateParts.day;
      const existing = byDay.get(day) ?? {
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      };

      existing.calories += parseNumber(meal.calories);
      existing.protein += parseNumber(meal.protein);
      existing.carbs += parseNumber(meal.carbs);
      existing.fat += parseNumber(meal.fat);

      byDay.set(day, existing);
    }

    const blockerDayKeys = await this.streakService.getAppliedStreakBlockerDayKeys(userId);
    const calendarDays: CalendarDay[] = [];
    let metGoalDays = 0;
    let registeredDays = 0;
    let totalCalories = 0;
    let totalProtein = 0;
    let totalCarbs = 0;
    let totalFat = 0;

    for (let day = 1; day <= daysInMonth; day++) {
      const totals = byDay.get(day);
      const dayKey = `${year}-${String(monthIndex + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
      if (!totals) {
        if (blockerDayKeys.has(dayKey)) {
          calendarDays.push({ day, status: 'streak_blocker_applied' });
        } else {
          calendarDays.push({ day, status: 'no_record' });
        }
        continue;
      }

      const reachedGoal = hasReachedCalorieGoal({
        consumedCalories: totals.calories,
        dailyCalorieGoal: calorieGoal,
        objective: user?.objective,
      });
      calendarDays.push({
        day,
        status: reachedGoal ? 'goal_achieved' : 'meal_registered',
      });

      if (reachedGoal) {
        metGoalDays += 1;
      }

      registeredDays += 1;
      totalCalories += totals.calories;
      totalProtein += totals.protein;
      totalCarbs += totals.carbs;
      totalFat += totals.fat;
    }

    const nowParts = this.getDatePartsInAppTimeZone(new Date());
    const isCurrentMonth =
      nowParts.year === year && nowParts.month === monthIndex + 1;
    const elapsedDays = isCurrentMonth
      ? Math.min(nowParts.day, daysInMonth)
      : daysInMonth;

    const streakDays = await this.streakService.getUserStreak(userId);
    const consistencyPercent =
      elapsedDays > 0 ? Math.round((registeredDays / elapsedDays) * 100) : 0;
    const avgDailyCalories =
      registeredDays > 0 ? Math.round(totalCalories / registeredDays) : 0;
    const avgDailyProtein = registeredDays > 0 ? totalProtein / registeredDays : 0;
    const avgDailyCarbs = registeredDays > 0 ? totalCarbs / registeredDays : 0;
    const avgDailyFat = registeredDays > 0 ? totalFat / registeredDays : 0;

    const startWeight = this.resolveMonthStartWeight(
      baselineEntry?.weight,
      monthWeightEntries[0]?.weight,
      user?.weight,
    );
    const endWeight = this.resolveMonthEndWeight(
      latestMonthEntry?.weight,
      monthWeightEntries[monthWeightEntries.length - 1]?.weight,
      user?.weight,
    );
    const weightDeltaKg = Number((endWeight - startWeight).toFixed(1));
    const weightDifferenceKg = Number(Math.abs(weightDeltaKg).toFixed(1));
    const weightDirection = this.getWeightDirection(weightDeltaKg);

    const carbsPercent = this.goalPercent(avgDailyCarbs, carbsGoal);
    const proteinPercent = this.goalPercent(avgDailyProtein, proteinGoal);
    const fatPercent = this.goalPercent(avgDailyFat, fatGoal);

    return {
      month: `${year}-${String(monthIndex + 1).padStart(2, '0')}`,
      streakDays,
      streakMessage: 'Continue registrando para não perder!',
      calendar: {
        year,
        month: monthIndex + 1,
        daysInMonth,
        days: calendarDays,
      },
      report: {
        metGoalDays,
        elapsedDays,
        registeredDays,
        consistencyPercent,
        avgDailyCalories,
        weightDeltaKg,
        weightDifferenceKg,
        weightDirection,
      },
      highlight: {
        title: 'Distribuição entre macronutrientes',
        description: '',
        macroProgress: [
          {
            key: 'carbs',
            label: 'Carboidratos',
            percent: carbsPercent,
          },
          {
            key: 'protein',
            label: 'Proteínas',
            percent: proteinPercent,
          },
          {
            key: 'fat',
            label: 'Gorduras',
            percent: fatPercent,
          },
        ],
      },
    };
  }

  async getWeightHistory(userId: string, query: GetWeightHistoryDto) {
    const { start, end, selectedPeriod } = this.resolveHistoryRange(query);

    const [entries, latestBeforeStart] = await Promise.all([
      this.userWeightEntryModel.findAll({
        where: {
          userId,
          recordedAt: {
            [Op.gte]: start,
            [Op.lte]: end,
          },
        },
        order: [['recordedAt', 'ASC']],
        attributes: ['weight', 'recordedAt'],
      }),
      this.userWeightEntryModel.findOne({
        where: {
          userId,
          recordedAt: {
            [Op.lt]: start,
          },
        },
        order: [['recordedAt', 'DESC']],
        attributes: ['weight', 'recordedAt'],
      }),
    ]);

    const points = entries.map((entry) => ({
      date: this.toDateTimeText(entry.recordedAt),
      weight: Number(parseNumber(entry.weight).toFixed(1)),
    }));

    if (latestBeforeStart) {
      points.unshift({
        date: this.toDateTimeText(start),
        weight: Number(parseNumber(latestBeforeStart.weight).toFixed(1)),
      });
    }

    return {
      range: {
        startDate: this.toDateText(start),
        endDate: this.toDateText(end),
        selectedPeriod,
      },
      points,
    };
  }

  private parseMonth(month?: string): { year: number; monthIndex: number } {
    if (!month) {
      const now = this.getDatePartsInAppTimeZone(new Date());
      return {
        year: now.year,
        monthIndex: now.month - 1,
      };
    }

    const [yearText, monthText] = month.split('-');
    const year = Number(yearText);
    const monthNumber = Number(monthText);

    return {
      year,
      monthIndex: monthNumber - 1,
    };
  }

  private resolveMonthStartWeight(
    baselineAtOrBeforeMonthStart: unknown,
    firstInMonth: unknown,
    fallback: unknown,
  ): number {
    return parseNumber(
      baselineAtOrBeforeMonthStart ?? firstInMonth ?? fallback,
      0,
    );
  }

  private resolveMonthEndWeight(
    latestInMonthOrBeforeEnd: unknown,
    latestInMonth: unknown,
    fallback: unknown,
  ): number {
    return parseNumber(latestInMonthOrBeforeEnd ?? latestInMonth ?? fallback, 0);
  }

  private getWeightDirection(deltaKg: number): 'lost' | 'gained' | 'stable' {
    if (Math.abs(deltaKg) < 0.1) {
      return 'stable';
    }

    return deltaKg < 0 ? 'lost' : 'gained';
  }

  private resolveHistoryRange(query: GetWeightHistoryDto): {
    start: Date;
    end: Date;
    selectedPeriod: string;
  } {
    const now = new Date();
    const period = query.period ?? '30';

    if (period === 'custom' && query.startDate && query.endDate) {
      const start = new Date(`${query.startDate}T00:00:00.000Z`);
      const end = new Date(`${query.endDate}T23:59:59.999Z`);
      return { start, end, selectedPeriod: 'custom' };
    }

    const days = Number(period);
    const safeDays = Number.isFinite(days) && days > 0 ? days : 30;
    const end = new Date(now);
    const start = new Date(now);
    start.setUTCDate(start.getUTCDate() - (safeDays - 1));
    start.setUTCHours(0, 0, 0, 0);
    end.setUTCHours(23, 59, 59, 999);

    return {
      start,
      end,
      selectedPeriod: String(safeDays),
    };
  }

  private toDateText(date: Date): string {
    return date.toISOString().slice(0, 10);
  }

  private toDateTimeText(date: Date): string {
    return date.toISOString();
  }

  private goalPercent(value: number, goal: number): number {
    if (goal <= 0) {
      return 0;
    }

    const percent = Math.round((value / goal) * 100);
    if (percent < 0) {
      return 0;
    }

    if (percent > 100) {
      return 100;
    }

    return percent;
  }

  private getDatePartsInAppTimeZone(date: Date): {
    year: number;
    month: number;
    day: number;
  } {
    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: this.appTimeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });

    const parts = formatter.formatToParts(date);
    const year = Number(parts.find((part) => part.type === 'year')?.value ?? 0);
    const month = Number(parts.find((part) => part.type === 'month')?.value ?? 0);
    const day = Number(parts.find((part) => part.type === 'day')?.value ?? 0);

    return { year, month, day };
  }

  private resolveAppTimeZone(): string {
    const fromEnv = process.env.APP_TIME_ZONE?.trim();
    if (fromEnv) {
      return fromEnv;
    }

    // Não usar o timezone do host (ex.: UTC em cloud) — isso desloca o dia
    // do calendário em relação ao fuso local do usuário (Brasil).
    return FALLBACK_TIME_ZONE;
  }
}
