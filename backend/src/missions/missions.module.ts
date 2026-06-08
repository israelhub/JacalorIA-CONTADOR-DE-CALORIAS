import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { User } from '../auth/models/user.model';
import { Meal } from '../meals/models/meal.model';
import { Mission } from './models/mission.model';
import { StoreCatalogItem } from './models/store-catalog-item.model';
import { UserCurrencyTransaction } from './models/user-currency-transaction.model';
import { MissionsController } from './missions.controller';
import { MissionsService } from './missions.service';
import { StoreCatalogService } from './store-catalog.service';
import { StreakModule } from '../streak/streak.module';

@Module({
  imports: [
    StreakModule,
    SequelizeModule.forFeature([
      Mission,
      Meal,
      User,
      UserCurrencyTransaction,
      StoreCatalogItem,
    ]),
  ],
  controllers: [MissionsController],
  providers: [MissionsService, StoreCatalogService],
  exports: [StoreCatalogService],
})
export class MissionsModule {}
