import { Inject, Injectable } from '@nestjs/common';
import { AnalyzeFoodDto } from './dto/analyze-food.dto';
import {
  FOOD_ANALYSIS_PROVIDER,
  FoodAnalysisProvider,
  FoodAnalysisResponse,
} from './providers/food-analysis.provider';
import { FoodNutritionRagService } from './services/food-nutrition-rag.service';
import { AnalyticsService } from '../analytics/analytics.service';

@Injectable()
export class AiService {
  constructor(
    @Inject(FOOD_ANALYSIS_PROVIDER)
    private readonly foodAnalysisProvider: FoodAnalysisProvider,
    private readonly foodNutritionRagService: FoodNutritionRagService,
    private readonly analyticsService: AnalyticsService,
  ) {}

  async analyzeFood(
    analyzeFoodDto: AnalyzeFoodDto,
    userId: string,
  ): Promise<FoodAnalysisResponse> {
    const hasImage = Boolean(analyzeFoodDto.imageBase64?.trim());
    const itemCount = Array.isArray(analyzeFoodDto.items)
      ? analyzeFoodDto.items.length
      : undefined;
    const stopwatchStarted = Date.now();

    await this.analyticsService.trackSafe(userId, {
      eventName: 'ai_analyze_requested',
      properties: {
        has_image: hasImage,
        item_count: itemCount ?? null,
        source: 'server',
      },
    });

    try {
      const providerResponse =
        await this.foodAnalysisProvider.analyzeFood(analyzeFoodDto);
      const enriched =
        await this.foodNutritionRagService.enrichAnalysis(providerResponse);

      await this.analyticsService.trackSafe(userId, {
        eventName: 'ai_analyze_succeeded',
        properties: {
          has_image: hasImage,
          item_count: itemCount ?? enriched.items?.length ?? null,
          latency_ms: Date.now() - stopwatchStarted,
          source: 'server',
        },
      });

      return enriched;
    } catch (error) {
      await this.analyticsService.trackSafe(userId, {
        eventName: 'ai_analyze_failed',
        properties: {
          has_image: hasImage,
          latency_ms: Date.now() - stopwatchStarted,
          error_code:
            error instanceof Error ? error.name || 'error' : 'error',
          source: 'server',
        },
      });
      throw error;
    }
  }
}
