import {
  Injectable,
  InternalServerErrorException,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AnalyzeFoodDto } from '../dto/analyze-food.dto';
import { FoodItemInputDto } from '../dto/food-item-input.dto';
import { FOOD_VISION_SYSTEM_PROMPT } from '../prompts/food-vision-system-prompt';
import {
  FoodAnalysisItem,
  FoodAnalysisProvider,
  FoodAnalysisResponse,
  FoodAnalysisTotals,
  FoodNutritionLabel,
} from './food-analysis.provider';

const AI_OVERLOAD_MESSAGE =
  'Estamos enfrentando uma sobrecarga na IA. Tente novamente em alguns instantes.';
const TOTAL_TIMEOUT_MS = 120_000;
const MAX_MODELS = 3;
const DEFAULT_PRIMARY_MODEL = 'gemini-3.1-flash-lite';
const DEFAULT_FALLBACK_MODELS = 'gemini-2.5-flash,gemini-2.5-flash-lite';

@Injectable()
export class FoodAnalysisProviderImpl implements FoodAnalysisProvider {
  private readonly logger = new Logger(FoodAnalysisProviderImpl.name);

  constructor(private readonly configService: ConfigService) {}

  async analyzeFood(analyzeFoodDto: AnalyzeFoodDto): Promise<FoodAnalysisResponse> {
    const apiKey = this.configService.get<string>('API_KEY');
    if (!apiKey) {
      throw new InternalServerErrorException('API_KEY não configurada');
    }

    const models = this.resolveModels();
    const { contents } = this.buildRequestContents(analyzeFoodDto);
    const deadlineAt = Date.now() + TOTAL_TIMEOUT_MS;
    let lastErrorMessage = 'nenhuma tentativa concluída';

    for (let index = 0; index < models.length; index += 1) {
      const model = models[index];
      const remainingMs = deadlineAt - Date.now();
      if (remainingMs <= 0) {
        break;
      }

      try {
        return await this.callGeminiModel({
          apiKey,
          model,
          contents,
          timeoutMs: remainingMs,
        });
      } catch (error) {
        lastErrorMessage = this.describeError(error);
        this.logger.warn(
          `Falha no modelo ${model} (tentativa ${index + 1}/${models.length}): ${lastErrorMessage}`,
        );
      }
    }

    this.logger.error(
      `Todos os modelos falharam ou o timeout de ${TOTAL_TIMEOUT_MS}ms foi atingido. Último erro: ${lastErrorMessage}`,
    );
    throw new ServiceUnavailableException(AI_OVERLOAD_MESSAGE);
  }

  private resolveModels(): string[] {
    const configuredChain = this.configService.get<string>('GEMINI_MODELS')?.trim();
    if (configuredChain) {
      return this.parseModelList(configuredChain);
    }

    const primary = this.configService.get<string>(
      'GEMINI_MODEL',
      DEFAULT_PRIMARY_MODEL,
    );
    const fallbacks = this.configService.get<string>(
      'GEMINI_FALLBACK_MODELS',
      DEFAULT_FALLBACK_MODELS,
    );

    return this.parseModelList(`${primary},${fallbacks}`);
  }

  private parseModelList(value: string): string[] {
    const models: string[] = [];
    const seen = new Set<string>();

    for (const part of value.split(',')) {
      const model = part.trim();
      if (!model || seen.has(model)) {
        continue;
      }

      seen.add(model);
      models.push(model);
      if (models.length >= MAX_MODELS) {
        break;
      }
    }

    return models.length > 0 ? models : [DEFAULT_PRIMARY_MODEL];
  }

  private buildRequestContents(analyzeFoodDto: AnalyzeFoodDto): {
    contents: Array<Record<string, unknown>>;
  } {
    const manualText = analyzeFoodDto.manualText?.trim();
    const hasItems = Boolean(analyzeFoodDto.items?.length);
    const hasManualText = Boolean(manualText);

    const payload = hasManualText
      ? this.buildManualTextPrompt(manualText!)
      : hasItems
        ? this.buildReanalysisPrompt(analyzeFoodDto.items!)
        : this.buildImageAnalysisPrompt();

    const contents =
      hasManualText || hasItems
        ? [
            {
              role: 'user',
              parts: [{ text: payload }],
            },
          ]
        : [
            {
              role: 'user',
              parts: [
                { text: payload },
                {
                  inlineData: {
                    mimeType: analyzeFoodDto.mimeType ?? 'image/jpeg',
                    data: analyzeFoodDto.imageBase64,
                  },
                },
              ],
            },
          ];

    return { contents };
  }

  private async callGeminiModel(params: {
    apiKey: string;
    model: string;
    contents: Array<Record<string, unknown>>;
    timeoutMs: number;
  }): Promise<FoodAnalysisResponse> {
    const { apiKey, model, contents, timeoutMs } = params;
    const fetchFn = globalThis.fetch as unknown as (
      input: string,
      init: Record<string, unknown>,
    ) => Promise<any>;

    const controller = new AbortController();
    const timeoutHandle = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const response = await fetchFn(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          signal: controller.signal,
          body: JSON.stringify({
            systemInstruction: {
              parts: [{ text: FOOD_VISION_SYSTEM_PROMPT }],
            },
            contents,
            generationConfig: {
              temperature: 0.2,
              responseMimeType: 'application/json',
            },
          }),
        },
      );

      if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(
          `HTTP ${response.status}: ${errorBody.slice(0, 500)}`,
        );
      }

      const responseBody = (await response.json()) as {
        candidates?: Array<{
          content?: { parts?: Array<{ text?: string }> };
        }>;
      };

      const text = responseBody.candidates?.[0]?.content?.parts
        ?.map((part) => part.text ?? '')
        .join('')
        .trim();

      if (!text) {
        throw new Error('Resposta vazia do provedor de IA');
      }

      const normalizedText = this.extractJsonText(text);

      try {
        return this.normalizeAnalysisResponse(
          JSON.parse(normalizedText) as Record<string, unknown>,
        );
      } catch {
        throw new Error('Resposta inválida (JSON) do provedor de IA');
      }
    } catch (error) {
      if (this.isAbortError(error)) {
        throw new Error(`Timeout após ${timeoutMs}ms`);
      }
      throw error;
    } finally {
      clearTimeout(timeoutHandle);
    }
  }

  private isAbortError(error: unknown): boolean {
    if (!error || typeof error !== 'object') {
      return false;
    }

    const name = 'name' in error ? String(error.name) : '';
    return name === 'AbortError' || name === 'TimeoutError';
  }

  private describeError(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }

    return String(error);
  }

  private buildImageAnalysisPrompt(): string {
    return 'Analise a imagem enviada e retorne a estimativa nutricional no JSON solicitado, com alimentos, gramas, calorias, proteínas, carboidratos, gorduras e justificativa curta.';
  }

  private buildManualTextPrompt(manualText: string): string {
    return [
      'O usuário digitou a refeição abaixo. Identifique os alimentos e as quantidades consumidas.',
      'Se houver dados de tabela nutricional (porção de referência + kcal/macros + quanto consumiu), EXTRAIA-OS em nutritionLabel com os valores da TABELA e deixe calories/protein/carbs/fat do item em 0 — o sistema calculará a proporção.',
      'Priorize sempre a tabela nutricional informada pelo usuário sobre qualquer estimativa.',
      'Retorne apenas o JSON solicitado, sem texto fora do JSON.',
      'Texto do usuário:',
      manualText,
    ].join('\n');
  }

  private buildReanalysisPrompt(items: FoodItemInputDto[]): string {
    const itemsText = items
      .map((item) => {
        const unit = item.unit?.trim() || 'g';
        return `${item.name}: ${item.grams} ${unit}`;
      })
      .join('\n');

    return [
      'Recalcule a estimativa nutricional total do prato com base nos itens já corrigidos pelo usuário.',
      'Retorne o mesmo JSON solicitado anteriormente, sem incluir texto fora do JSON.',
      'Itens corrigidos:',
      itemsText,
    ].join('\n');
  }

  private normalizeAnalysisResponse(raw: Record<string, unknown>): FoodAnalysisResponse {
    const items = this.normalizeItems(raw.items ?? raw.alimentos_identificados);
    const totals = this.normalizeTotals(raw.totals ?? raw.estimativa_nutricional_total ?? raw.total);
    const justification = this.normalizeText(raw.justification ?? raw.justificativa_da_estimativa);

    return {
      items,
      totals,
      justification,
    };
  }

  private normalizeItems(value: unknown): FoodAnalysisItem[] {
    if (!Array.isArray(value)) {
      return [];
    }

    return value.map((item) => {
      const foodItem = item as Record<string, unknown>;
      const nutritionLabel = this.normalizeNutritionLabel(
        foodItem.nutritionLabel ??
          foodItem.nutrition_label ??
          foodItem.tabela_nutricional,
      );

      return {
        name: this.normalizeText(foodItem.name ?? foodItem.alimento ?? foodItem.food),
        grams: this.normalizeNumber(foodItem.grams ?? foodItem.peso_em_gramas),
        calories: this.normalizeNumber(foodItem.calories ?? foodItem.calorias),
        protein: this.normalizeNumber(foodItem.protein ?? foodItem.proteinas),
        carbs: this.normalizeNumber(foodItem.carbs ?? foodItem.carboidratos),
        fat: this.normalizeNumber(foodItem.fat ?? foodItem.gorduras),
        ...(nutritionLabel ? { nutritionLabel } : {}),
      };
    });
  }

  private normalizeNutritionLabel(value: unknown): FoodNutritionLabel | undefined {
    if (!value || typeof value !== 'object') {
      return undefined;
    }

    const label = value as Record<string, unknown>;
    const referenceGrams = this.normalizeNumber(
      label.referenceGrams ??
        label.reference_grams ??
        label.porcao_referencia_g ??
        label.porcao,
    );
    const calories = this.normalizeNumber(label.calories ?? label.calorias);

    if (referenceGrams <= 0 || calories < 0) {
      return undefined;
    }

    const protein = this.normalizeOptionalMacro(label.protein ?? label.proteinas);
    const carbs = this.normalizeOptionalMacro(label.carbs ?? label.carboidratos);
    const fat = this.normalizeOptionalMacro(label.fat ?? label.gorduras);

    return {
      referenceGrams,
      calories,
      ...(protein !== undefined ? { protein } : {}),
      ...(carbs !== undefined ? { carbs } : {}),
      ...(fat !== undefined ? { fat } : {}),
    };
  }

  private normalizeOptionalMacro(value: unknown): number | undefined {
    if (value === undefined || value === null || value === '') {
      return undefined;
    }

    return this.normalizeNumber(value);
  }

  private normalizeTotals(value: unknown): FoodAnalysisTotals {
    const totals = (value ?? {}) as Record<string, unknown>;

    return {
      calories: this.normalizeNumber(totals.calories ?? totals.calorias),
      protein: this.normalizeNumber(totals.protein ?? totals.proteinas),
      carbs: this.normalizeNumber(totals.carbs ?? totals.carboidratos),
      fat: this.normalizeNumber(totals.fat ?? totals.gorduras),
    };
  }

  private normalizeText(value: unknown): string {
    if (typeof value === 'string') {
      return value.trim();
    }

    return '';
  }

  private extractJsonText(text: string): string {
    const fencedMatch = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
    const fencedText = fencedMatch?.[1]?.trim();
    if (fencedText) {
      return fencedText;
    }

    const firstBrace = text.indexOf('{');
    const lastBrace = text.lastIndexOf('}');
    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      return text.slice(firstBrace, lastBrace + 1).trim();
    }

    return text;
  }

  private normalizeNumber(value: unknown): number {
    if (typeof value === 'number' && Number.isFinite(value)) {
      return value;
    }

    if (typeof value === 'string') {
      const parsed = Number(value.replace(',', '.'));
      if (Number.isFinite(parsed)) {
        return parsed;
      }
    }

    return 0;
  }
}
