import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';
import { AnalyticsDashboardService } from './analytics-dashboard.service';
import { DashboardTokenGuard } from './guards/dashboard-token.guard';
import { AnalyticsEvent } from './models/analytics-event.model';
import { User } from '../auth/models/user.model';

@Module({
  imports: [SequelizeModule.forFeature([AnalyticsEvent, User])],
  controllers: [AnalyticsController],
  providers: [
    AnalyticsService,
    AnalyticsDashboardService,
    DashboardTokenGuard,
  ],
  exports: [AnalyticsService],
})
export class AnalyticsModule {}
