import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { MealsService } from './meals.service';
import { MealsController } from './meals.controller';
import { Meal } from './models/meal.model';

@Module({
  imports: [SequelizeModule.forFeature([Meal])],
  controllers: [MealsController],
  providers: [MealsService],
  exports: [MealsService],
})
export class MealsModule {}
