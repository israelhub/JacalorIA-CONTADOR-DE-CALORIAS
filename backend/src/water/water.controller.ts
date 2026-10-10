import { Body, Controller, Get, Post, Query, Req, UnauthorizedException, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AddWaterDto } from './dto/add-water.dto';
import { WaterService } from './water.service';

@Controller('water')
@UseGuards(JwtAuthGuard)
export class WaterController {
  constructor(private readonly waterService: WaterService) {}

  @Get()
  list(
    @Req() req: any,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.waterService.list(this.requireUserId(req), startDate, endDate);
  }

  @Post()
  add(@Body() dto: AddWaterDto, @Req() req: any) {
    return this.waterService.add(this.requireUserId(req), dto);
  }

  private requireUserId(req: any): string {
    const userId = req.user?.sub as string | undefined;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }
    return userId;
  }
}
