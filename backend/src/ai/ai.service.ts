import { Inject, Injectable } from '@nestjs/common';
import { AnalyzeFoodDto } from './dto/analyze-food.dto';
import {
  FOOD_ANALYSIS_PROVIDER,
  FoodAnalysisProvider,
  FoodAnalysisResponse,
} from './providers/food-analysis.provider';
import { FoodNutritionRagService } from './services/food-nutrition-rag.service';

@Injectable()
export class AiService {
  constructor(
    @Inject(FOOD_ANALYSIS_PROVIDER)
    private readonly foodAnalysisProvider: FoodAnalysisProvider,
    private readonly foodNutritionRagService: FoodNutritionRagService,
  ) {}

  async analyzeFood(analyzeFoodDto: AnalyzeFoodDto): Promise<FoodAnalysisResponse> {
    const providerResponse = await this.foodAnalysisProvider.analyzeFood(analyzeFoodDto);
    return this.foodNutritionRagService.enrichAnalysis(providerResponse);
  }
}
