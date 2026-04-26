import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { User } from '../auth/models/user.model';
import { Meal } from '../meals/models/meal.model';
import { Mission } from './models/mission.model';
import { MissionsController } from './missions.controller';
import { MissionsService } from './missions.service';

@Module({
  imports: [SequelizeModule.forFeature([Mission, Meal, User])],
  controllers: [MissionsController],
  providers: [MissionsService],
})
export class MissionsModule {}
