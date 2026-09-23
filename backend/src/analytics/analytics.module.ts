import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';
import { AnalyticsDashboardService } from './analytics-dashboard.service';
import { InfraMetricsService } from './infra-metrics.service';
import { DashboardTokenGuard } from './guards/dashboard-token.guard';
import { AnalyticsEvent } from './models/analytics-event.model';
import { User } from '../auth/models/user.model';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule, SequelizeModule.forFeature([AnalyticsEvent, User])],
  controllers: [AnalyticsController],
  providers: [
    AnalyticsService,
    AnalyticsDashboardService,
    InfraMetricsService,
    DashboardTokenGuard,
  ],
  exports: [AnalyticsService, InfraMetricsService],
})
export class AnalyticsModule {}
