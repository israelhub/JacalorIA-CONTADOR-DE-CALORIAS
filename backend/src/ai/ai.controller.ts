import {
  Body,
  Controller,
  Post,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AiService } from './ai.service';
import { AnalyzeFoodDto } from './dto/analyze-food.dto';

@Controller('ai')
@UseGuards(JwtAuthGuard)
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('food/analyze')
  analyzeFood(@Body() analyzeFoodDto: AnalyzeFoodDto, @Req() req: any) {
    const userId = req.user?.sub as string | undefined;
    if (!userId) {
      throw new UnauthorizedException('Usuário não autenticado');
    }

    return this.aiService.analyzeFood(analyzeFoodDto, userId);
  }
}
