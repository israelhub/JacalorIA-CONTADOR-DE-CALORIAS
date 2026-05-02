import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
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

  async findAll(userId: string): Promise<Meal[]> {
    return this.mealModel.findAll({
      where: { userId, status: MealStatus.Active },
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
