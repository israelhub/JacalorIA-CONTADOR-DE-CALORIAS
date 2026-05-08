import {
  Body,
  Controller,
  Get,
  Post,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MissionsService } from './missions.service';
import { PurchaseAvatarFrameDto } from './dto/purchase-avatar-frame.dto';
import { PurchaseAvatarBackgroundDto } from './dto/purchase-avatar-background.dto';
import { PurchaseOffensiveBlockerDto } from './dto/purchase-offensive-blocker.dto';

@Controller('missions')
@UseGuards(JwtAuthGuard)
export class MissionsController {
  constructor(private readonly missionsService: MissionsService) {}

  @Get()
  async getMissions(@Req() req: any) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.missionsService.getMissions(userId);
  }

  @Get('store')
  async getStore(@Req() req: any) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.missionsService.getStore(userId);
  }

  @Post('store/avatar-frames/purchase')
  async purchaseAvatarFrame(@Req() req: any, @Body() dto: PurchaseAvatarFrameDto) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.missionsService.purchaseAvatarFrame(userId, dto.frameId);
  }

  @Post('store/avatar-backgrounds/purchase')
  async purchaseAvatarBackground(
    @Req() req: any,
    @Body() dto: PurchaseAvatarBackgroundDto,
  ) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.missionsService.purchaseAvatarBackground(userId, dto.backgroundId);
  }

  @Post('store/offensive-blockers/purchase')
  async purchaseOffensiveBlocker(
    @Req() req: any,
    @Body() dto: PurchaseOffensiveBlockerDto,
  ) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.missionsService.purchaseOffensiveBlocker(
      userId,
      dto.blockerId,
      dto.quantity,
    );
  }

  @Get('wallet/gold-statement')
  async getGoldStatement(@Req() req: any) {
    const userId = req.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.missionsService.getGoldStatement(userId);
  }
}
