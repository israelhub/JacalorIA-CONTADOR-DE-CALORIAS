import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { User } from '../auth/models/user.model';
import { WaterIntakeEntry } from './models/water-intake-entry.model';
import { WaterController } from './water.controller';
import { WaterService } from './water.service';

@Module({
  imports: [SequelizeModule.forFeature([WaterIntakeEntry, User])],
  controllers: [WaterController],
  providers: [WaterService],
})
export class WaterModule {}
