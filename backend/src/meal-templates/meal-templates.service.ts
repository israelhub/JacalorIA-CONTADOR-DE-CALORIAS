import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import {
  MealTemplate,
  MealTemplateStatus,
} from './models/meal-template.model';
import { CreateMealTemplateDto } from './dto/create-meal-template.dto';

@Injectable()
export class MealTemplatesService {
  constructor(
    @InjectModel(MealTemplate)
    private readonly mealTemplateModel: typeof MealTemplate,
  ) {}

  async create(
    createDto: CreateMealTemplateDto,
    userId: string,
  ): Promise<MealTemplate> {
    return this.mealTemplateModel.create({
      ...createDto,
      userId,
      status: MealTemplateStatus.Active,
    });
  }

  async findAll(userId: string): Promise<MealTemplate[]> {
    return this.mealTemplateModel.findAll({
      where: {
        userId,
        status: MealTemplateStatus.Active,
      },
      order: [['createdAt', 'DESC']],
    });
  }

  async softDelete(templateId: string, userId: string): Promise<void> {
    const [affected] = await this.mealTemplateModel.update(
      { status: MealTemplateStatus.Deleted },
      {
        where: {
          id: templateId,
          userId,
          status: MealTemplateStatus.Active,
        },
      },
    );

    if (!affected) {
      throw new NotFoundException('Refeição salva não encontrada');
    }
  }
}
