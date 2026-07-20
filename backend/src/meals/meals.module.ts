import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { MealsService } from './meals.service';
import { MealsController } from './meals.controller';
import { Meal } from './models/meal.model';
import { AnalyticsModule } from '../analytics/analytics.module';

@Module({
  imports: [SequelizeModule.forFeature([Meal]), AnalyticsModule],
  controllers: [MealsController],
  providers: [MealsService],
  exports: [MealsService],
})
export class MealsModule {}
