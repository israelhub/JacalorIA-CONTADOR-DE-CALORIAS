import {
  Body,
  Controller,
  Get,
  Post,
  Query,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AnalyticsService } from './analytics.service';
import { AnalyticsDashboardService } from './analytics-dashboard.service';
import { TrackEventsDto } from './dto/track-events.dto';
import { DashboardTokenGuard } from './guards/dashboard-token.guard';

@Controller('analytics')
export class AnalyticsController {
  constructor(
    private readonly analyticsService: AnalyticsService,
    private readonly dashboardService: AnalyticsDashboardService,
  ) {}

  @Post('events')
  @UseGuards(JwtAuthGuard)
  async trackEvents(@Body() dto: TrackEventsDto, @Req() req: any) {
    const userId = req.user?.sub as string | undefined;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.analyticsService.trackMany(userId, dto.events);
  }

  @Get('dashboard')
  @UseGuards(DashboardTokenGuard)
  async getDashboard(
    @Query('days') days?: string,
    @Query('betaStart') betaStart?: string,
    @Query('betaEnd') betaEnd?: string,
  ) {
    return this.dashboardService.getDashboard({
      days: days ? Number(days) : undefined,
      betaStart,
      betaEnd,
    });
  }
}
