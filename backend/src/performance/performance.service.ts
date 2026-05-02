import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { User } from '../auth/models/user.model';
import { Meal, MealStatus } from '../meals/models/meal.model';
import { UserWeightEntry } from './models/user-weight-entry.model';

type DayStatus = 'goal_achieved' | 'meal_registered' | 'no_record';

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

@Injectable()
export class PerformanceService {
  constructor(
    @InjectModel(Meal)
    private readonly mealModel: typeof Meal,
    @InjectModel(User)
    private readonly userModel: typeof User,
    @InjectModel(UserWeightEntry)
    private readonly userWeightEntryModel: typeof UserWeightEntry,
  ) {}

  async getMonthlyPerformance(userId: string, month?: string) {
    const { year, monthIndex } = this.parseMonth(month);
    const monthStart = new Date(Date.UTC(year, monthIndex, 1));
    const monthEnd = new Date(Date.UTC(year, monthIndex + 1, 1));
    const daysInMonth = new Date(Date.UTC(year, monthIndex + 1, 0)).getUTCDate();

    const [user, meals, weightEntries] = await Promise.all([
      this.userModel.findByPk(userId, {
        attributes: [
          'dailyCalorieGoal',
          'dailyProteinGoal',
          'dailyCarbsGoal',
          'dailyFatGoal',
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
    ]);

    const calorieGoal = this.toNumber(user?.dailyCalorieGoal, 2000);
    const proteinGoal = this.toNumber(user?.dailyProteinGoal, 120);
    const carbsGoal = this.toNumber(user?.dailyCarbsGoal, 200);
    const fatGoal = this.toNumber(user?.dailyFatGoal, 60);

    const byDay = new Map<number, DailyTotals>();

    for (const meal of meals) {
      const date = new Date(meal.createdAt);
      const day = date.getUTCDate();
      const existing = byDay.get(day) ?? {
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      };

      existing.calories += this.toNumber(meal.calories);
      existing.protein += this.toNumber(meal.protein);
      existing.carbs += this.toNumber(meal.carbs);
      existing.fat += this.toNumber(meal.fat);

      byDay.set(day, existing);
    }

    const calendarDays: CalendarDay[] = [];
    let metGoalDays = 0;
    let registeredDays = 0;
    let totalCalories = 0;
    let totalProtein = 0;
    let totalCarbs = 0;
    let totalFat = 0;

    for (let day = 1; day <= daysInMonth; day++) {
      const totals = byDay.get(day);
      if (!totals) {
        calendarDays.push({ day, status: 'no_record' });
        continue;
      }

      const reachedGoal = totals.calories >= calorieGoal;
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

    const now = new Date();
    const isCurrentMonth =
      now.getUTCFullYear() === year && now.getUTCMonth() === monthIndex;
    const elapsedDays = isCurrentMonth
      ? Math.min(now.getUTCDate(), daysInMonth)
      : daysInMonth;

    const streakDays = this.calculateStreak(calendarDays, elapsedDays);
    const consistencyPercent =
      elapsedDays > 0 ? Math.round((registeredDays / elapsedDays) * 100) : 0;
    const avgDailyCalories =
      registeredDays > 0 ? Math.round(totalCalories / registeredDays) : 0;
    const avgDailyProtein = registeredDays > 0 ? totalProtein / registeredDays : 0;
    const avgDailyCarbs = registeredDays > 0 ? totalCarbs / registeredDays : 0;
    const avgDailyFat = registeredDays > 0 ? totalFat / registeredDays : 0;

    const startWeight =
      weightEntries.length > 0
        ? this.toNumber(weightEntries[0].weight)
        : this.toNumber(user?.weight, 0);
    const endWeight =
      weightEntries.length > 0
        ? this.toNumber(weightEntries[weightEntries.length - 1].weight)
        : this.toNumber(user?.weight, 0);
    const weightLostKg = Number(Math.max(startWeight - endWeight, 0).toFixed(1));

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
        weightLostKg,
      },
      highlight: {
        title: 'Destaque do mês',
        description: `Você bateu sua meta em ${metGoalDays} dias e manteve uma média de ${avgDailyCalories} kcal por dia. Continue assim: você está no caminho certo para seu objetivo!`,
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

  private parseMonth(month?: string): { year: number; monthIndex: number } {
    if (!month) {
      const now = new Date();
      return {
        year: now.getUTCFullYear(),
        monthIndex: now.getUTCMonth(),
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

  private calculateStreak(days: CalendarDay[], elapsedDays: number): number {
    let streak = 0;

    for (let day = elapsedDays; day >= 1; day--) {
      const status = days[day - 1]?.status;
      if (status === 'goal_achieved' || status === 'meal_registered') {
        streak += 1;
        continue;
      }

      break;
    }

    return streak;
  }

  private toNumber(value: unknown, fallback = 0): number {
    if (typeof value === 'number') {
      return Number.isFinite(value) ? value : fallback;
    }

    if (typeof value === 'string') {
      const parsed = Number(value.replace(',', '.'));
      return Number.isFinite(parsed) ? parsed : fallback;
    }

    return fallback;
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
}
