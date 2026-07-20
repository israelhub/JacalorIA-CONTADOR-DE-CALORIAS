import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { Meal } from './models/meal.model';
import { CreateMealDto } from './dto/create-meal.dto';
import { UpdateMealDto } from './dto/update-meal.dto';
import { MealStatus } from './models/meal.model';
import { AnalyticsService } from '../analytics/analytics.service';

@Injectable()
export class MealsService {
  constructor(
    @InjectModel(Meal)
    private readonly mealModel: typeof Meal,
    private readonly analyticsService: AnalyticsService,
  ) {}

  async create(createMealDto: CreateMealDto, userId: string): Promise<Meal> {
    const meal = await this.mealModel.create({
      ...createMealDto,
      userId,
      status: MealStatus.Active,
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
