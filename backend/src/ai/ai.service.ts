import { Inject, Injectable } from '@nestjs/common';
import { AnalyzeFoodDto } from './dto/analyze-food.dto';
import {
  FOOD_ANALYSIS_PROVIDER,
  FoodAnalysisProvider,
  FoodAnalysisResponse,
} from './providers/food-analysis.provider';

@Injectable()
export class AiService {
  constructor(
    @Inject(FOOD_ANALYSIS_PROVIDER)
    private readonly foodAnalysisProvider: FoodAnalysisProvider,
  ) {}

  async analyzeFood(analyzeFoodDto: AnalyzeFoodDto): Promise<FoodAnalysisResponse> {
    return this.foodAnalysisProvider.analyzeFood(analyzeFoodDto);
  }
}