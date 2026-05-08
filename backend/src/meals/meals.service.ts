import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { Meal } from './models/meal.model';
import { CreateMealDto } from './dto/create-meal.dto';
import { UpdateMealDto } from './dto/update-meal.dto';
import { MealStatus } from './models/meal.model';

@Injectable()
export class MealsService {
  constructor(
    @InjectModel(Meal)
    private readonly mealModel: typeof Meal,
  ) {}

  async create(createMealDto: CreateMealDto, userId: string): Promise<Meal> {
    return this.mealModel.create({
      ...createMealDto,
      userId,
      status: MealStatus.Active,
    });
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
