import { Inject, Injectable } from '@nestjs/common';
import { AnalyzeFoodDto } from './dto/analyze-food.dto';
import {
  FOOD_ANALYSIS_PROVIDER,
  FoodAnalysisProvider,
  FoodAnalysisProviderMeta,
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
  ): Promise<
    FoodAnalysisResponse & {
      meta: {
        model: string;
        cacheHit: boolean;
        attempts: number;
        failedModels: string[];
        promptTokens: number | null;
        outputTokens: number | null;
        totalTokens: number | null;
        latencyMs: number;
      };
    }
  > {
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
      let meta: FoodAnalysisProviderMeta | null = null;

      if (isImageAnalysis) {
        const contentHash = this.hashImage(analyzeFoodDto.imageBase64!);
        const cacheKey = `${userId}:${contentHash}`;
        const cachedAnalysis = await this.foodImageAnalysisModel.findOne({
          where: { userId, contentHash },
          order: [['updatedAt', 'DESC']],
        });

        if (cachedAnalysis) {
          cacheHit = true;
          // Reaplica o RAG (nomes/kcal TACO) — o cache pode ser de antes do
          // matching atual; sem isso o cliente recebe o nome cru da IA.
          result = await this.foodNutritionRagService.enrichAnalysis(
            cachedAnalysis.result as FoodAnalysisResponse,
          );
          await this.foodImageAnalysisModel.update(
            { result },
            { where: { id: cachedAnalysis.id } },
          );
          meta = {
            model: 'cache',
            attempts: 0,
            failedModels: [],
            promptTokens: null,
            outputTokens: null,
            totalTokens: null,
          };
        } else {
          const runningAnalysis = this.analysesInProgress.get(cacheKey);
          if (runningAnalysis) {
            cacheHit = true;
            result = await runningAnalysis;
            meta = {
              model: 'cache',
              attempts: 0,
              failedModels: [],
              promptTokens: null,
              outputTokens: null,
              totalTokens: null,
            };
          } else {
            let resolvedMeta: FoodAnalysisProviderMeta | null = null;
            const analysisPromise = this.analyzeAndCacheImage(
              analyzeFoodDto,
              userId,
              contentHash,
            ).then((outcome) => {
              resolvedMeta = outcome.meta;
              return outcome.analysis;
            });
            this.analysesInProgress.set(cacheKey, analysisPromise);

            try {
              result = await analysisPromise;
              meta = resolvedMeta;
            } finally {
              this.analysesInProgress.delete(cacheKey);
            }
          }
        }
      } else {
        const outcome = await this.runAnalysis(analyzeFoodDto);
        result = outcome.analysis;
        meta = outcome.meta;
      }

      await this.analyticsService.trackSafe(userId, {
        eventName: 'ai_analyze_succeeded',
        properties: {
          has_image: hasImage,
          item_count: itemCount ?? result.items?.length ?? null,
          cache_hit: cacheHit,
          latency_ms: Date.now() - stopwatchStarted,
          source: 'server',
          model: meta?.model ?? (cacheHit ? 'cache' : 'unknown'),
          attempts: meta?.attempts ?? null,
          failed_models: meta?.failedModels ?? [],
          prompt_tokens: meta?.promptTokens ?? null,
          output_tokens: meta?.outputTokens ?? null,
          total_tokens: meta?.totalTokens ?? null,
        },
      });

      return {
        ...result,
        meta: {
          model: meta?.model ?? (cacheHit ? 'cache' : 'unknown'),
          cacheHit,
          attempts: meta?.attempts ?? 0,
          failedModels: meta?.failedModels ?? [],
          promptTokens: meta?.promptTokens ?? null,
          outputTokens: meta?.outputTokens ?? null,
          totalTokens: meta?.totalTokens ?? null,
          latencyMs: Date.now() - stopwatchStarted,
        },
      };
    } catch (error) {
      const failedModels =
        error && typeof error === 'object' && 'failedModels' in error
          ? (error as { failedModels?: string[] }).failedModels
          : undefined;
      const lastModel = failedModels?.length
        ? failedModels[failedModels.length - 1]
        : 'unknown';
      await this.analyticsService.trackSafe(userId, {
        eventName: 'ai_analyze_failed',
        properties: {
          has_image: hasImage,
          latency_ms: Date.now() - stopwatchStarted,
          error_code:
            error instanceof Error ? error.name || 'error' : 'error',
          error_message:
            error instanceof Error
              ? error.message.slice(0, 240)
              : String(error).slice(0, 240),
          source: 'server',
          model: lastModel,
          failed_models: failedModels ?? [],
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

  private async runAnalysis(analyzeFoodDto: AnalyzeFoodDto): Promise<{
    analysis: FoodAnalysisResponse;
    meta: FoodAnalysisProviderMeta;
  }> {
    const providerResponse =
      await this.foodAnalysisProvider.analyzeFood(analyzeFoodDto);
    return {
      analysis: await this.foodNutritionRagService.enrichAnalysis(
        providerResponse.analysis,
      ),
      meta: providerResponse.meta,
    };
  }

  private async analyzeAndCacheImage(
    analyzeFoodDto: AnalyzeFoodDto,
    userId: string,
    contentHash: string,
  ): Promise<{ analysis: FoodAnalysisResponse; meta: FoodAnalysisProviderMeta }> {
    const outcome = await this.runAnalysis(analyzeFoodDto);

    await this.foodImageAnalysisModel.upsert({
      userId,
      contentHash,
      result: outcome.analysis,
    });

    return outcome;
  }
}
