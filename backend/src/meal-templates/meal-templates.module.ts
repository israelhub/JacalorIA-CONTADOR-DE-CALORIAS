import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { MealTemplatesService } from './meal-templates.service';
import { MealTemplatesController } from './meal-templates.controller';
import { MealTemplate } from './models/meal-template.model';

@Module({
  imports: [SequelizeModule.forFeature([MealTemplate])],
  controllers: [MealTemplatesController],
  providers: [MealTemplatesService],
  exports: [MealTemplatesService],
})
export class MealTemplatesModule {}
