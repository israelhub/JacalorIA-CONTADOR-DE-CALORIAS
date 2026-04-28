import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Meal } from './models/meal.model';
import { CreateMealDto } from './dto/create-meal.dto';

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
    });
  }

  async findAll(userId: string): Promise<Meal[]> {
    return this.mealModel.findAll({
      where: { userId },
      order: [['createdAt', 'DESC']],
    });
  }
}
