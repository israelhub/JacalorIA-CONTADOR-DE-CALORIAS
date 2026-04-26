import {
  Controller,
  Get,
  Query,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { GetMonthlyPerformanceDto } from './dto/get-monthly-performance.dto';
import { PerformanceService } from './performance.service';

@Controller('performance')
@UseGuards(JwtAuthGuard)
export class PerformanceController {
  constructor(private readonly performanceService: PerformanceService) {}

  @Get('monthly')
  async getMonthlyPerformance(
    @Req() req: any,
    @Query() query: GetMonthlyPerformanceDto,
  ) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.performanceService.getMonthlyPerformance(userId, query.month);
  }
}
