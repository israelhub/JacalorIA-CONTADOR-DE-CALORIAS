import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { User } from '../auth/models/user.model';
import { Meal } from '../meals/models/meal.model';
import { UserWeightEntry } from './models/user-weight-entry.model';
import { PerformanceController } from './performance.controller';
import { PerformanceService } from './performance.service';
import { StreakModule } from '../streak/streak.module';

@Module({
  imports: [StreakModule, SequelizeModule.forFeature([Meal, User, UserWeightEntry])],
  controllers: [PerformanceController],
  providers: [PerformanceService],
})
export class PerformanceModule {}
