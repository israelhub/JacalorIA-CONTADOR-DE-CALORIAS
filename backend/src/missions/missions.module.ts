import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { User } from '../auth/models/user.model';
import { Meal } from '../meals/models/meal.model';
import { UserWeightEntry } from '../performance/models/user-weight-entry.model';
import { Mission } from './models/mission.model';
import { StoreCatalogItem } from './models/store-catalog-item.model';
import { StorePurchase } from './models/store-purchase.model';
import { UserCurrencyTransaction } from './models/user-currency-transaction.model';
import { UserMission } from './models/user-mission.model';
import { MissionsController } from './missions.controller';
import { MissionsService } from './missions.service';
import { StoreCatalogService } from './store-catalog.service';
import { StreakModule } from '../streak/streak.module';
import { AnalyticsModule } from '../analytics/analytics.module';

@Module({
  imports: [
    StreakModule,
    AnalyticsModule,
    SequelizeModule.forFeature([
      Mission,
      Meal,
      User,
      UserWeightEntry,
      UserCurrencyTransaction,
      UserMission,
      StoreCatalogItem,
      StorePurchase,
    ]),
  ],
  controllers: [MissionsController],
  providers: [MissionsService, StoreCatalogService],
  exports: [StoreCatalogService],
})
export class MissionsModule {}
