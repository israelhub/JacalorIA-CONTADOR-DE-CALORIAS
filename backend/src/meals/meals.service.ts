import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { Meal } from './models/meal.model';
import { CreateMealDto } from './dto/create-meal.dto';
import { UpdateMealDto } from './dto/update-meal.dto';
import { MealStatus, MealType } from './models/meal.model';
import { AnalyticsService } from '../analytics/analytics.service';
import { StreakService } from '../streak/streak.service';

@Injectable()
export class MealsService {
  constructor(
    @InjectModel(Meal)
    private readonly mealModel: typeof Meal,
    private readonly analyticsService: AnalyticsService,
    private readonly streakService: StreakService,
  ) {}

  async create(createMealDto: CreateMealDto, userId: string): Promise<Meal> {
    const now = new Date();
    const todayKey = this.streakService.toDayKeyInAppTimeZone(now);
    const { createdAt: createdAtInput, ...mealFields } = createMealDto;

    let mealCreatedAt = now;
    if (createdAtInput) {
      const parsed = new Date(createdAtInput);
      if (!Number.isNaN(parsed.getTime())) {
        const parsedKey = this.streakService.toDayKeyInAppTimeZone(parsed);
        mealCreatedAt = parsedKey > todayKey ? now : parsed;
      }
    }

    const mealDayKey = this.streakService.toDayKeyInAppTimeZone(mealCreatedAt);
    const countsForStreak = mealDayKey === todayKey;

    const meal = await this.mealModel.create({
      ...mealFields,
      mealType: createMealDto.mealType ?? MealType.Free,
      userId,
      status: MealStatus.Active,
      createdAt: mealCreatedAt,
      countsForStreak,
    });

    const hasImage = Boolean(createMealDto.imageUrl?.trim());
    const hasAnalysisItems =
      Array.isArray(createMealDto.analysisItems) &&
      createMealDto.analysisItems.length > 0;

    await this.analyticsService.trackSafe(userId, {
      eventName: 'meal_saved',
      properties: {
        source: hasImage || hasAnalysisItems ? 'ai_photo' : 'manual',
        meal_id: meal.id,
        has_image: hasImage,
        has_analysis_items: hasAnalysisItems,
        calories: createMealDto.calories,
        meal_type: createMealDto.mealType ?? MealType.Free,
        counts_for_streak: countsForStreak,
        meal_day_key: mealDayKey,
      },
    });

    return meal;
  }

  async findAll(
    userId: string,
    filters?: {
      startDate?: string;
      endDate?: string;
    },
  ): Promise<Meal[]> {
    const where: Record<string, unknown> = {
      userId,
      status: MealStatus.Active,
    };

    if (filters?.startDate || filters?.endDate) {
      const createdAtFilter: Record<symbol, Date> = {};

      if (filters.startDate) {
        const startDate = new Date(filters.startDate);
        if (!Number.isNaN(startDate.getTime())) {
          createdAtFilter[Op.gte] = startDate;
        }
      }

      if (filters.endDate) {
        const endDate = new Date(filters.endDate);
        if (!Number.isNaN(endDate.getTime())) {
          createdAtFilter[Op.lt] = endDate;
        }
      }

      if (Object.getOwnPropertySymbols(createdAtFilter).length > 0) {
        where.createdAt = createdAtFilter;
      }
    }

    return this.mealModel.findAll({
      where,
      order: [['createdAt', 'DESC']],
    });
  }

  async update(
    mealId: string,
    updateMealDto: UpdateMealDto,
    userId: string,
  ): Promise<Meal> {
    const [affected] = await this.mealModel.update(updateMealDto, {
      where: {
        id: mealId,
        userId,
        status: MealStatus.Active,
      },
    });

    if (!affected) {
      throw new NotFoundException('Refeição não encontrada');
    }

    const meal = await this.mealModel.findOne({
      where: { id: mealId, userId, status: MealStatus.Active },
    });

    if (!meal) {
      throw new NotFoundException('Refeição não encontrada');
    }

    return meal;
  }

  async softDelete(mealId: string, userId: string): Promise<void> {
    const [affected] = await this.mealModel.update(
      { status: MealStatus.Deleted },
      {
        where: {
          id: mealId,
          userId,
          status: MealStatus.Active,
        },
      },
    );

    if (!affected) {
      throw new NotFoundException('Refeição não encontrada');
    }
  }
}
