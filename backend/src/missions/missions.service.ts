import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { User } from '../auth/models/user.model';
import { Meal, MealStatus } from '../meals/models/meal.model';
import { Mission, MissionAccent, MissionType } from './models/mission.model';

type DailyTotals = {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  meals: number;
  foods: Set<string>;
};

type MissionProgress = {
  progressCurrent: number;
};

@Injectable()
export class MissionsService {
  constructor(
    @InjectModel(Mission)
    private readonly missionModel: typeof Mission,
    @InjectModel(Meal)
    private readonly mealModel: typeof Meal,
    @InjectModel(User)
    private readonly userModel: typeof User,
  ) {}

  async getMissions(userId: string) {
    const now = new Date();
    const todayStart = this.getUtcDayStart(now);
    const weekStart = this.getUtcWeekStart(now);
    const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));

    const [user, missions, meals] = await Promise.all([
      this.userModel.findByPk(userId, {
        attributes: [
          'dailyCalorieGoal',
          'dailyProteinGoal',
          'dailyCarbsGoal',
          'dailyFatGoal',
        ],
      }),
      this.missionModel.findAll({
        where: { isActive: true },
        order: [
          ['type', 'ASC'],
          ['sortOrder', 'ASC'],
          ['createdAt', 'ASC'],
        ],
      }),
      this.mealModel.findAll({
        where: {
          userId,
          status: MealStatus.Active,
          createdAt: {
            [Op.gte]: monthStart,
            [Op.lt]: now,
          },
        },
        attributes: ['createdAt', 'calories', 'protein', 'carbs', 'fat', 'analysisItems'],
      }),
    ]);

    const dailyCalorieGoal = this.toNumber(user?.dailyCalorieGoal, 2000);
    const dailyProteinGoal = this.toNumber(user?.dailyProteinGoal, 120);
    const dailyCarbsGoal = this.toNumber(user?.dailyCarbsGoal, 200);
    const dailyFatGoal = this.toNumber(user?.dailyFatGoal, 60);

    const totalsByDay = new Map<string, DailyTotals>();

    for (const meal of meals) {
      const mealDate = new Date(meal.createdAt);
      const dayKey = this.toDayKey(mealDate);
      const dayTotals = totalsByDay.get(dayKey) ?? {
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        meals: 0,
        foods: new Set<string>(),
      };

      dayTotals.calories += this.toNumber(meal.calories);
      dayTotals.protein += this.toNumber(meal.protein);
      dayTotals.carbs += this.toNumber(meal.carbs);
      dayTotals.fat += this.toNumber(meal.fat);
      dayTotals.meals += 1;

      const items = Array.isArray(meal.analysisItems) ? meal.analysisItems : [];
      for (const item of items) {
        const name = typeof item?.name === 'string' ? item.name.trim().toLowerCase() : '';
        if (name) {
          dayTotals.foods.add(name);
        }
      }

      totalsByDay.set(dayKey, dayTotals);
    }

    const todayTotals = totalsByDay.get(this.toDayKey(todayStart));
    const weeklyEntries = this.collectDayTotalsInRange(totalsByDay, weekStart, now);
    const monthlyEntries = this.collectDayTotalsInRange(totalsByDay, monthStart, now);

    const metGoalToday = todayTotals ? todayTotals.calories >= dailyCalorieGoal : false;
    const metAllMacrosToday = todayTotals
      ? todayTotals.protein >= dailyProteinGoal &&
        todayTotals.carbs >= dailyCarbsGoal &&
        todayTotals.fat >= dailyFatGoal
      : false;

    const consecutiveDaysInWeek = this.calculateConsecutiveDays(
      totalsByDay,
      weekStart,
      this.getUtcDayStart(now),
    );
    const weeklyGoalDays = weeklyEntries.filter((entry) => entry.calories >= dailyCalorieGoal).length;
    const weeklyFoods = new Set<string>();
    for (const entry of weeklyEntries) {
      for (const food of entry.foods) {
        weeklyFoods.add(food);
      }
    }

    const monthlyGoalDays = monthlyEntries.filter((entry) => entry.calories >= dailyCalorieGoal).length;
    const monthlyRegisteredDays = monthlyEntries.length;
    const monthlyMacroDays = monthlyEntries.filter(
      (entry) =>
        entry.protein >= dailyProteinGoal &&
        entry.carbs >= dailyCarbsGoal &&
        entry.fat >= dailyFatGoal,
    ).length;

    const missionByKey = new Map<string, MissionProgress>([
      [
        'daily_protein_goal',
        {
          progressCurrent: Math.round(todayTotals?.protein ?? 0),
        },
      ],
      [
        'daily_three_meals',
        {
          progressCurrent: todayTotals?.meals ?? 0,
        },
      ],
      [
        'weekly_streak_5_days',
        {
          progressCurrent: consecutiveDaysInWeek,
        },
      ],
      [
        'weekly_goal_4_times',
        {
          progressCurrent: weeklyGoalDays,
        },
      ],
      [
        'weekly_variety_15_foods',
        {
          progressCurrent: weeklyFoods.size,
        },
      ],
      [
        'monthly_master_consistency',
        {
          progressCurrent: monthlyGoalDays,
        },
      ],
      [
        'monthly_objective_focus',
        {
          progressCurrent: monthlyRegisteredDays,
        },
      ],
      [
        'monthly_macro_hunter',
        {
          progressCurrent: monthlyMacroDays,
        },
      ],
    ]);

    const missionItems = missions.map((mission) => {
      const mapped = missionByKey.get(mission.key) ?? {
        progressCurrent: metGoalToday || metAllMacrosToday ? mission.targetValue : 0,
      };
      const progressTarget = Math.max(1, mission.targetValue || 1);
      const progressCurrent = Math.max(0, Math.min(mapped.progressCurrent, progressTarget));
      const percent = Math.round((progressCurrent / progressTarget) * 100);

      return {
        id: mission.id,
        key: mission.key,
        type: mission.type,
        title: mission.title,
        description: mission.description,
        accent: mission.accent,
        progressCurrent,
        progressTarget,
        progressLabel: `${progressCurrent}/${progressTarget}`,
        progressPercent: Math.max(0, Math.min(100, percent)),
        rewardGold: mission.rewardGold,
        rewardXp: mission.rewardXp,
      };
    });

    const sections = this.sectionOrder().map((section) => ({
      id: section.id,
      title: section.title,
      subtitle: section.subtitle,
      missions: missionItems.filter((mission) => mission.type === section.id),
    }));

    const completedMissions = missionItems.filter(
      (mission) => mission.progressCurrent >= mission.progressTarget,
    );

    const summaryGold = completedMissions.reduce(
      (sum, mission) => sum + this.toNumber(mission.rewardGold),
      0,
    );
    const summaryXp = completedMissions.reduce(
      (sum, mission) => sum + this.toNumber(mission.rewardXp),
      0,
    );

    return {
      summary: {
        gold: summaryGold,
        xp: summaryXp,
      },
      intro: {
        title: 'Bem-vindo às Missões!',
        description:
          'Complete missões diárias, semanais e desafios mensais para ganhar ouro e XP. Suba de nível e desbloqueie recompensas com o Jaca!',
      },
      sections,
    };
  }

  private sectionOrder(): Array<{ id: MissionType; title: string; subtitle: string }> {
    return [
      {
        id: 'daily',
        title: 'Missões diárias',
        subtitle: 'Renovam à meia-noite',
      },
      {
        id: 'weekly',
        title: 'Missões semanais',
        subtitle: 'Renovam toda segunda-feira',
      },
      {
        id: 'monthly',
        title: 'Desafios do mês',
        subtitle: 'Renovam no início de cada mês',
      },
    ];
  }

  private collectDayTotalsInRange(
    totalsByDay: Map<string, DailyTotals>,
    start: Date,
    end: Date,
  ): DailyTotals[] {
    const entries: DailyTotals[] = [];
    const cursor = new Date(start);

    while (cursor <= end) {
      const value = totalsByDay.get(this.toDayKey(cursor));
      if (value && value.meals > 0) {
        entries.push(value);
      }

      cursor.setUTCDate(cursor.getUTCDate() + 1);
    }

    return entries;
  }

  private calculateConsecutiveDays(
    totalsByDay: Map<string, DailyTotals>,
    rangeStart: Date,
    rangeEnd: Date,
  ): number {
    let streak = 0;
    const cursor = new Date(rangeEnd);

    while (cursor >= rangeStart) {
      const totals = totalsByDay.get(this.toDayKey(cursor));
      if (!totals || totals.meals <= 0) {
        break;
      }

      streak += 1;
      cursor.setUTCDate(cursor.getUTCDate() - 1);
    }

    return streak;
  }

  private getUtcDayStart(date: Date): Date {
    return new Date(
      Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
    );
  }

  private getUtcWeekStart(date: Date): Date {
    const dayStart = this.getUtcDayStart(date);
    const day = dayStart.getUTCDay();
    const offset = day === 0 ? 6 : day - 1;
    dayStart.setUTCDate(dayStart.getUTCDate() - offset);
    return dayStart;
  }

  private toDayKey(date: Date): string {
    return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}-${String(
      date.getUTCDate(),
    ).padStart(2, '0')}`;
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
}
