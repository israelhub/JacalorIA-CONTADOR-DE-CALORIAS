import { Body, Controller, Post } from '@nestjs/common';
import { AiService } from './ai.service';
import { AnalyzeFoodDto } from './dto/analyze-food.dto';

@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('food/analyze')
  analyzeFood(@Body() analyzeFoodDto: AnalyzeFoodDto) {
    return this.aiService.analyzeFood(analyzeFoodDto);
  }
}