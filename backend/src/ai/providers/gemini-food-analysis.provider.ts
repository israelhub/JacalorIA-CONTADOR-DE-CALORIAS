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
  FoodAnalysisProviderResult,
  FoodAnalysisResponse,
  FoodAnalysisTotals,
  FoodNutritionLabel,
} from './food-analysis.provider';

const AI_OVERLOAD_MESSAGE =
  'Estamos enfrentando uma sobrecarga na IA. Tente novamente em alguns instantes.';
// Budget total abaixo do CloudFront/nginx (120s). Preferimos falhar cedo a
// segurar o usuario em espera inutil — a UX pede analise rapida.
const TOTAL_TIMEOUT_MS = 55_000;
// Flash/vision normalmente responde em poucos segundos. Se passar disso,
// aborta e cai no proximo modelo em vez de "morrer" esperando.
const PER_MODEL_TIMEOUT_MS = 12_000;
// Apos timeout/429, nao gasta o budget de novo no mesmo modelo por um tempo
// (cota RPM e por modelo — deixa o fallback atender enquanto o primario esfria).
const MODEL_COOLDOWN_MS = 30_000;
const MAX_MODELS = 8;
const DEFAULT_PRIMARY_MODEL = 'gemini-3.5-flash-lite';
// Cada modelo tem cota RPM/RPD separada no AI Studio — a cadeia espalha a carga
// quando o primário toma 429 por minuto.
const DEFAULT_FALLBACK_MODELS = [
  'gemini-3.1-flash-lite',
  'gemini-2.5-flash-lite',
  'gemini-3-flash',
].join(',');

@Injectable()
export class FoodAnalysisProviderImpl implements FoodAnalysisProvider {
  private readonly logger = new Logger(FoodAnalysisProviderImpl.name);
  private readonly modelCooldownUntil = new Map<string, number>();

  constructor(private readonly configService: ConfigService) {}

  async analyzeFood(
    analyzeFoodDto: AnalyzeFoodDto,
  ): Promise<FoodAnalysisProviderResult> {
    const apiKey = this.configService.get<string>('API_KEY');
    if (!apiKey) {
      throw new InternalServerErrorException('API_KEY não configurada');
    }

    const models = this.resolveModels();
    const { contents } = this.buildRequestContents(analyzeFoodDto);
    const deadlineAt = Date.now() + TOTAL_TIMEOUT_MS;
    let lastErrorMessage = 'nenhuma tentativa concluída';
    const failedModels: string[] = [];
    let attempts = 0;

    for (let index = 0; index < models.length; index += 1) {
      const model = models[index];
      const remainingMs = deadlineAt - Date.now();
      if (remainingMs <= 0) {
        break;
      }

      if (this.isModelInCooldown(model)) {
        const hasLaterAvailable = models
          .slice(index + 1)
          .some((candidate) => !this.isModelInCooldown(candidate));
        if (hasLaterAvailable) {
          failedModels.push(model);
          lastErrorMessage = `cooldown ativo (${MODEL_COOLDOWN_MS}ms)`;
          this.logger.warn(
            `Pulando modelo ${model} (tentativa ${index + 1}/${models.length}): ${lastErrorMessage}`,
          );
          continue;
        }
        // Ultimo recurso: tenta mesmo em cooldown para nao devolver 503
        // instantaneo quando a cadeia inteira esfriou ao mesmo tempo.
        this.logger.warn(
          `Modelo ${model} em cooldown, mas sem alternativa livre — tentando mesmo assim`,
        );
      }

      attempts += 1;
      try {
        const { analysis, usage } = await this.callGeminiModel({
          apiKey,
          model,
          contents,
          timeoutMs: Math.min(remainingMs, PER_MODEL_TIMEOUT_MS),
        });
        return {
          analysis,
          meta: {
            model,
            attempts,
            failedModels,
            promptTokens: usage.promptTokens,
            outputTokens: usage.outputTokens,
            totalTokens: usage.totalTokens,
          },
        };
      } catch (error) {
        lastErrorMessage = this.describeError(error);
        failedModels.push(model);
        this.markModelCooldown(model, lastErrorMessage);
        this.logger.warn(
          `Falha no modelo ${model} (tentativa ${index + 1}/${models.length}): ${lastErrorMessage}`,
        );
      }
    }

    this.logger.error(
      `Todos os modelos falharam ou o timeout de ${TOTAL_TIMEOUT_MS}ms foi atingido. Último erro: ${lastErrorMessage}`,
    );
    const overload = new ServiceUnavailableException(AI_OVERLOAD_MESSAGE);
    (overload as Error & { failedModels?: string[] }).failedModels = failedModels;
    throw overload;
  }

  private isModelInCooldown(model: string): boolean {
    const until = this.modelCooldownUntil.get(model) ?? 0;
    if (until <= Date.now()) {
      if (until > 0) {
        this.modelCooldownUntil.delete(model);
      }
      return false;
    }
    return true;
  }

  private markModelCooldown(model: string, errorMessage: string): void {
    if (!this.shouldCooldown(errorMessage)) {
      return;
    }
    this.modelCooldownUntil.set(model, Date.now() + MODEL_COOLDOWN_MS);
    this.logger.warn(
      `Modelo ${model} em cooldown por ${MODEL_COOLDOWN_MS}ms apos: ${errorMessage}`,
    );
  }

  private shouldCooldown(errorMessage: string): boolean {
    const normalized = errorMessage.toLowerCase();
    return (
      normalized.includes('timeout') ||
      normalized.includes('429') ||
      normalized.includes('rate') ||
      normalized.includes('quota') ||
      normalized.includes('resource_exhausted') ||
      normalized.includes('resource exhausted') ||
      normalized.includes('unavailable')
    );
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
  }): Promise<{
    analysis: FoodAnalysisResponse;
    usage: {
      promptTokens: number | null;
      outputTokens: number | null;
      totalTokens: number | null;
    };
  }> {
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
        usageMetadata?: {
          promptTokenCount?: number;
          candidatesTokenCount?: number;
          totalTokenCount?: number;
        };
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
        return {
          analysis: this.normalizeAnalysisResponse(
            JSON.parse(normalizedText) as Record<string, unknown>,
          ),
          usage: {
            promptTokens: this.nullableNumber(
              responseBody.usageMetadata?.promptTokenCount,
            ),
            outputTokens: this.nullableNumber(
              responseBody.usageMetadata?.candidatesTokenCount,
            ),
            totalTokens: this.nullableNumber(
              responseBody.usageMetadata?.totalTokenCount,
            ),
          },
        };
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

  private nullableNumber(value: unknown): number | null {
    const n = Number(value);
    return Number.isFinite(n) ? n : null;
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
    return [
      'Analise a imagem enviada e retorne a estimativa nutricional no JSON solicitado, com alimentos, gramas, calorias, proteínas, carboidratos, gorduras e justificativa curta.',
      'No campo name, inclua tipo, corte e preparo (ex.: "Frango peito grelhado", "Arroz branco cozido", "Feijão preto cozido"). Não use só "Arroz" ou "Feijão": no prato brasileiro o default é cozido. Só use pratos compostos (ex.: "Arroz carreteiro") com evidência clara na foto.',
    ].join(' ');
  }

  private buildManualTextPrompt(manualText: string): string {
    return [
      'O usuário digitou a refeição abaixo. Identifique os alimentos e as quantidades consumidas.',
      'No campo name, preserve tipo, corte e preparo quando o usuário informar. Se o usuário escrever só "arroz"/"feijão" sem detalhe, normalize para o preparo típico (ex.: "Arroz branco cozido", "Feijão preto cozido"), salvo se indicar prato composto (carreteiro, à grega etc.).',
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
      'Preserve no campo name o tipo, corte e preparo informados nos itens corrigidos. Se o item vier só como "Arroz" ou "Feijão", normalize para o preparo típico (ex.: "Arroz branco cozido").',
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
