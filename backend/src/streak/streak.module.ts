import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { Meal } from '../meals/models/meal.model';
import { StreakService } from './streak.service';

@Module({
  imports: [SequelizeModule.forFeature([Meal])],
  providers: [StreakService],
  exports: [StreakService],
})
export class StreakModule {}

