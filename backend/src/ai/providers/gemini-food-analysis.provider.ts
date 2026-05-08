import {
  BadGatewayException,
  InternalServerErrorException,
  Injectable,
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
} from './food-analysis.provider';

@Injectable()
export class FoodAnalysisProviderImpl implements FoodAnalysisProvider {
  constructor(private readonly configService: ConfigService) {}

  async analyzeFood(analyzeFoodDto: AnalyzeFoodDto): Promise<FoodAnalysisResponse> {
    const apiKey = this.configService.get<string>('API_KEY');
    if (!apiKey) {
      throw new InternalServerErrorException('API_KEY não configurada');
    }

    const model = this.configService.get<string>(
      'GEMINI_MODEL',
      'gemini-2.5-flash-lite',
    );
    const payload = analyzeFoodDto.items?.length
      ? this.buildReanalysisPrompt(analyzeFoodDto.items)
      : this.buildImageAnalysisPrompt();

    const contents = analyzeFoodDto.items?.length
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

    const fetchFn = globalThis.fetch as unknown as (
      input: string,
      init: Record<string, unknown>,
    ) => Promise<any>;

    const response = await fetchFn(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
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
      throw new BadGatewayException(
        `Falha ao analisar alimento com o provedor de IA (${response.status}): ${errorBody}`,
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
      throw new BadGatewayException('O provedor de IA retornou uma resposta vazia');
    }

    const normalizedText = this.extractJsonText(text);

    return this.normalizeAnalysisResponse(
      JSON.parse(normalizedText) as Record<string, unknown>,
    );
  }

  private buildImageAnalysisPrompt(): string {
    return 'Analise a imagem enviada e retorne a estimativa nutricional no JSON solicitado, com alimentos, gramas, calorias, proteínas, carboidratos, gorduras e justificativa curta.';
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
      return {
        name: this.normalizeText(foodItem.name ?? foodItem.alimento ?? foodItem.food),
        grams: this.normalizeNumber(foodItem.grams ?? foodItem.peso_em_gramas),
        calories: this.normalizeNumber(foodItem.calories ?? foodItem.calorias),
        protein: this.normalizeNumber(foodItem.protein ?? foodItem.proteinas),
        carbs: this.normalizeNumber(foodItem.carbs ?? foodItem.carboidratos),
        fat: this.normalizeNumber(foodItem.fat ?? foodItem.gorduras),
      };
    });
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