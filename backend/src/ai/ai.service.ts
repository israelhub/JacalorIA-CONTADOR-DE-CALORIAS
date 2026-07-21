import { Inject, Injectable } from '@nestjs/common';
import { AnalyzeFoodDto } from './dto/analyze-food.dto';
import {
  FOOD_ANALYSIS_PROVIDER,
  FoodAnalysisProvider,
  FoodAnalysisResponse,
} from './providers/food-analysis.provider';
import { FoodNutritionRagService } from './services/food-nutrition-rag.service';
import { AnalyticsService } from '../analytics/analytics.service';
import { createHash } from 'crypto';
import { InjectModel } from '@nestjs/sequelize';
import { FoodImageAnalysis } from './models/food-image-analysis.model';

@Injectable()
export class AiService {
  private readonly analysesInProgress = new Map<
    string,
    Promise<FoodAnalysisResponse>
  >();

  constructor(
    @Inject(FOOD_ANALYSIS_PROVIDER)
    private readonly foodAnalysisProvider: FoodAnalysisProvider,
    private readonly foodNutritionRagService: FoodNutritionRagService,
    private readonly analyticsService: AnalyticsService,
    @InjectModel(FoodImageAnalysis)
    private readonly foodImageAnalysisModel: typeof FoodImageAnalysis,
  ) {}

  async analyzeFood(
    analyzeFoodDto: AnalyzeFoodDto,
    userId: string,
  ): Promise<FoodAnalysisResponse> {
    const hasImage = Boolean(analyzeFoodDto.imageBase64?.trim());
    const hasManualText = Boolean(analyzeFoodDto.manualText?.trim());
    const itemCount = Array.isArray(analyzeFoodDto.items)
      ? analyzeFoodDto.items.length
      : undefined;
    const isImageAnalysis = hasImage && !hasManualText && !itemCount;
    const stopwatchStarted = Date.now();

    await this.analyticsService.trackSafe(userId, {
      eventName: 'ai_analyze_requested',
      properties: {
        has_image: hasImage,
        has_manual_text: hasManualText,
        item_count: itemCount ?? null,
        source: 'server',
      },
    });

    try {
      let cacheHit = false;
      let result: FoodAnalysisResponse;

      if (isImageAnalysis) {
        const contentHash = this.hashImage(analyzeFoodDto.imageBase64!);
        const cacheKey = `${userId}:${contentHash}`;
        const cachedAnalysis = await this.foodImageAnalysisModel.findOne({
          where: { userId, contentHash },
          order: [['updatedAt', 'DESC']],
        });

        if (cachedAnalysis) {
          cacheHit = true;
          result = cachedAnalysis.result;
        } else {
          const runningAnalysis = this.analysesInProgress.get(cacheKey);
          if (runningAnalysis) {
            cacheHit = true;
            result = await runningAnalysis;
          } else {
            const analysisPromise = this.analyzeAndCacheImage(
              analyzeFoodDto,
              userId,
              contentHash,
            );
            this.analysesInProgress.set(cacheKey, analysisPromise);

            try {
              result = await analysisPromise;
            } finally {
              this.analysesInProgress.delete(cacheKey);
            }
          }
        }
      } else {
        result = await this.runAnalysis(analyzeFoodDto);
      }

      await this.analyticsService.trackSafe(userId, {
        eventName: 'ai_analyze_succeeded',
        properties: {
          has_image: hasImage,
          item_count: itemCount ?? result.items?.length ?? null,
          cache_hit: cacheHit,
          latency_ms: Date.now() - stopwatchStarted,
          source: 'server',
        },
      });

      return result;
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

  private hashImage(imageBase64: string): string {
    const normalizedBase64 = imageBase64.replace(/\s/g, '');
    const imageBytes = Buffer.from(normalizedBase64, 'base64');
    return createHash('sha256').update(imageBytes).digest('hex');
  }

  private async runAnalysis(
    analyzeFoodDto: AnalyzeFoodDto,
  ): Promise<FoodAnalysisResponse> {
    const providerResponse =
      await this.foodAnalysisProvider.analyzeFood(analyzeFoodDto);
    return this.foodNutritionRagService.enrichAnalysis(providerResponse);
  }

  private async analyzeAndCacheImage(
    analyzeFoodDto: AnalyzeFoodDto,
    userId: string,
    contentHash: string,
  ): Promise<FoodAnalysisResponse> {
    const result = await this.runAnalysis(analyzeFoodDto);

    await this.foodImageAnalysisModel.upsert({
      userId,
      contentHash,
      result,
    });

    return result;
  }
}
