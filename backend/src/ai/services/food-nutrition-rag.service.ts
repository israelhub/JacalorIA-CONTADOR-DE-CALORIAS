import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectConnection } from '@nestjs/sequelize';
import { QueryTypes, Sequelize } from 'sequelize';
import {
  FoodAnalysisItem,
  FoodAnalysisResponse,
  FoodAnalysisTotals,
} from '../providers/food-analysis.provider';

type TacoFoodRow = {
  descricao: string | null;
  categoria: string | null;
  energia_kcal: string | null;
  proteina_g: string | null;
  carboidrato_g: string | null;
  lipideos_g: string | null;
};

type TacoFoodEntry = {
  description: string;
  normalizedDescription: string;
  tokens: string[];
  tokenSet: Set<string>;
  category: string | null;
  caloriesPer100g: number | null;
  proteinPer100g: number | null;
  carbsPer100g: number | null;
  fatPer100g: number | null;
};

type FoodMatch = {
  score: number;
  food: TacoFoodEntry;
};

type RecipeTemplate = {
  pattern: RegExp;
  ingredients: Array<{ name: string; ratio: number }>;
};

const MATCH_THRESHOLD = 0.58;
const RECIPE_INGREDIENT_THRESHOLD = 0.5;
const CACHE_TTL_MS = 10 * 60 * 1000;

const STOP_WORDS = new Set([
  'de',
  'da',
  'do',
  'das',
  'dos',
  'com',
  'sem',
  'ao',
  'aos',
  'na',
  'no',
  'nas',
  'nos',
  'e',
  'ou',
  'em',
]);

const RECIPE_TEMPLATES: RecipeTemplate[] = [
  {
    pattern: /\bbolo\b/,
    ingredients: [
      { name: 'farinha de trigo', ratio: 0.3 },
      { name: 'acucar', ratio: 0.2 },
      { name: 'ovo de galinha', ratio: 0.2 },
      { name: 'leite integral', ratio: 0.2 },
      { name: 'manteiga', ratio: 0.1 },
    ],
  },
  {
    pattern: /\bpizza\b/,
    ingredients: [
      { name: 'farinha de trigo', ratio: 0.45 },
      { name: 'queijo mussarela', ratio: 0.25 },
      { name: 'molho de tomate', ratio: 0.15 },
      { name: 'oleo de soja', ratio: 0.05 },
      { name: 'presunto', ratio: 0.1 },
    ],
  },
  {
    pattern: /\blasanh[ae]\b/,
    ingredients: [
      { name: 'macarrao', ratio: 0.3 },
      { name: 'carne bovina', ratio: 0.3 },
      { name: 'queijo mussarela', ratio: 0.2 },
      { name: 'molho de tomate', ratio: 0.2 },
    ],
  },
];

@Injectable()
export class FoodNutritionRagService {
  private readonly logger = new Logger(FoodNutritionRagService.name);
  private foodsCache: TacoFoodEntry[] | null = null;
  private foodsCacheExpiresAt = 0;
  private resolvedTableName: string | null = null;
  private hasResolvedTableName = false;

  constructor(
    @InjectConnection() private readonly sequelize: Sequelize,
    private readonly configService: ConfigService,
  ) {}

  async enrichAnalysis(response: FoodAnalysisResponse): Promise<FoodAnalysisResponse> {
    try {
      if (!response.items?.length) {
        return response;
      }

      const foods = await this.loadFoods();

      let labelMatches = 0;
      let dbMatches = 0;
      let recipeMatches = 0;
      let aiFallbacks = 0;

      const items = response.items.map((item) => {
        if (this.hasValidNutritionLabel(item)) {
          labelMatches += 1;
          return this.calculateFromNutritionLabel(item);
        }

        if (!foods.length) {
          aiFallbacks += 1;
          return this.markAsAiEstimate(item);
        }

        const dbMatch = this.findBestFoodMatch(item.name, foods, MATCH_THRESHOLD);
        if (dbMatch) {
          dbMatches += 1;
          return this.calculateFromMatchedFood(item, dbMatch.food, 'taco_db');
        }

        const recipeItem = this.estimateRecipeFromIngredients(item, foods);
        if (recipeItem) {
          recipeMatches += 1;
          return recipeItem;
        }

        aiFallbacks += 1;
        return this.markAsAiEstimate(item);
      });

      return {
        items,
        totals: this.sumTotals(items),
        justification: this.buildJustification(response.justification, {
          labelMatches,
          dbMatches,
          recipeMatches,
          aiFallbacks,
        }),
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(`Falha no enriquecimento RAG de calorias: ${message}`);
      return this.withFallbackSource(response);
    }
  }

  private withFallbackSource(response: FoodAnalysisResponse): FoodAnalysisResponse {
    const items = (response.items ?? []).map((item) => {
      if (this.hasValidNutritionLabel(item)) {
        return this.calculateFromNutritionLabel(item);
      }

      return this.markAsAiEstimate(item);
    });
    return {
      ...response,
      items,
      totals: this.sumTotals(items),
    };
  }

  private async loadFoods(): Promise<TacoFoodEntry[]> {
    if (this.foodsCache && Date.now() < this.foodsCacheExpiresAt) {
      return this.foodsCache;
    }

    const tableName = await this.resolveTableName();
    if (!tableName) {
      return [];
    }

    const rows = await this.sequelize.query<TacoFoodRow>(
      `select descricao, categoria, energia_kcal, proteina_g, carboidrato_g, lipideos_g from public.${tableName};`,
      { type: QueryTypes.SELECT },
    );

    const foods = rows
      .map((row) => this.mapTacoRow(row))
      .filter((entry): entry is TacoFoodEntry => entry !== null);

    this.foodsCache = foods;
    this.foodsCacheExpiresAt = Date.now() + CACHE_TTL_MS;
    return foods;
  }

  private async resolveTableName(): Promise<string | null> {
    if (this.hasResolvedTableName) {
      return this.resolvedTableName;
    }

    this.hasResolvedTableName = true;

    const configured = this.sanitizeTableName(
      this.configService.get<string>('TACO_TABLE_NAME'),
    );

    const candidates = this.uniqueTableNames([
      configured,
      'tco_4a_edicao',
      'taco_4a_edicao',
    ]);

    for (const tableName of candidates) {
      const exists = await this.sequelize.query<{ exists: boolean }>(
        `
          select exists (
            select 1
            from information_schema.tables
            where table_schema = 'public'
              and table_name = :tableName
          ) as "exists";
        `,
        {
          type: QueryTypes.SELECT,
          replacements: { tableName },
        },
      );

      if (exists[0]?.exists) {
        this.resolvedTableName = tableName;
        return tableName;
      }
    }

    this.logger.warn(
      `Nenhuma tabela TACO encontrada. Tentativas: ${candidates.join(', ')}`,
    );
    this.resolvedTableName = null;
    return null;
  }

  private uniqueTableNames(values: Array<string | null>): string[] {
    const normalized = values.filter((value): value is string => !!value);
    return [...new Set(normalized)];
  }

  private sanitizeTableName(value: string | undefined): string | null {
    const trimmed = value?.trim();
    if (!trimmed) {
      return null;
    }

    if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(trimmed)) {
      this.logger.warn(`TACO_TABLE_NAME inválida: ${trimmed}`);
      return null;
    }

    return trimmed.toLowerCase();
  }

  private mapTacoRow(row: TacoFoodRow): TacoFoodEntry | null {
    const description = (row.descricao ?? '').trim();
    if (!description) {
      return null;
    }

    const normalizedDescription = this.normalizeName(description);
    const tokens = this.tokenize(normalizedDescription);

    return {
      description,
      normalizedDescription,
      tokens,
      tokenSet: new Set(tokens),
      category: row.categoria,
      caloriesPer100g: this.parseTacoNumber(row.energia_kcal),
      proteinPer100g: this.parseTacoNumber(row.proteina_g),
      carbsPer100g: this.parseTacoNumber(row.carboidrato_g),
      fatPer100g: this.parseTacoNumber(row.lipideos_g),
    };
  }

  private parseTacoNumber(value: string | null): number | null {
    if (!value) {
      return null;
    }

    const normalized = value.trim().toLowerCase();
    if (!normalized || normalized === 'na' || normalized === 'n/a' || normalized === '-') {
      return null;
    }

    if (normalized === 'tr' || normalized === 'traço' || normalized === 'traco') {
      return 0;
    }

    let numeric = normalized;
    if (numeric.includes(',') && numeric.includes('.')) {
      numeric = numeric.replace(/\./g, '').replace(',', '.');
    } else if (numeric.includes(',')) {
      numeric = numeric.replace(',', '.');
    }

    numeric = numeric.replace(/[^0-9.-]/g, '');
    if (!numeric || numeric === '-' || numeric === '.' || numeric === '-.') {
      return null;
    }

    const parsed = Number(numeric);
    return Number.isFinite(parsed) ? parsed : null;
  }

  private normalizeName(value: string): string {
    return value
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  private tokenize(normalized: string): string[] {
    const baseTokens = normalized.split(' ').filter((token) => token.length > 1);
    const filtered = baseTokens.filter((token) => !STOP_WORDS.has(token));
    return filtered.length ? filtered : baseTokens;
  }

  private findBestFoodMatch(
    foodName: string,
    foods: TacoFoodEntry[],
    threshold: number,
  ): FoodMatch | null {
    const normalized = this.normalizeName(foodName);
    if (!normalized) {
      return null;
    }

    const tokens = this.tokenize(normalized);

    let best: FoodMatch | null = null;

    for (const food of foods) {
      if (!this.isPotentialCandidate(normalized, tokens, food)) {
        continue;
      }

      const score = this.scoreMatch(normalized, tokens, food);
      if (!best || score > best.score) {
        best = { score, food };
      }
    }

    if (!best || best.score < threshold) {
      return null;
    }

    return best;
  }

  private isPotentialCandidate(
    normalized: string,
    tokens: string[],
    food: TacoFoodEntry,
  ): boolean {
    if (
      food.normalizedDescription.includes(normalized) ||
      normalized.includes(food.normalizedDescription)
    ) {
      return true;
    }

    for (const token of tokens) {
      if (food.tokenSet.has(token)) {
        return true;
      }
    }

    return false;
  }

  private scoreMatch(
    normalized: string,
    tokens: string[],
    food: TacoFoodEntry,
  ): number {
    if (normalized === food.normalizedDescription) {
      return 1;
    }

    let shared = 0;
    for (const token of tokens) {
      if (food.tokenSet.has(token)) {
        shared += 1;
      }
    }

    const tokenOverlap = tokens.length ? shared / tokens.length : 0;
    const foodCoverage = food.tokens.length ? shared / food.tokens.length : 0;
    const hasSubstring =
      food.normalizedDescription.includes(normalized) ||
      normalized.includes(food.normalizedDescription);
    const sameFirstToken =
      tokens.length > 0 && food.tokens.length > 0 && tokens[0] === food.tokens[0];

    const tokenBonus = tokens.length === 1 && shared === 1 ? 0.08 : 0;

    return Math.min(
      1,
      tokenOverlap * 0.5 +
        foodCoverage * 0.2 +
        (hasSubstring ? 0.25 : 0) +
        (sameFirstToken ? 0.12 : 0) +
        tokenBonus,
    );
  }

  private calculateFromMatchedFood(
    item: FoodAnalysisItem,
    food: TacoFoodEntry,
    source: 'taco_db' | 'recipe_decomposition',
    matchedFood?: string,
  ): FoodAnalysisItem {
    const grams = this.safeNumber(item.grams);
    const calories = this.calcValueFromPer100g(
      food.caloriesPer100g,
      grams,
      this.safeNumber(item.calories),
    );
    const protein = this.calcValueFromPer100g(
      food.proteinPer100g,
      grams,
      this.safeNumber(item.protein),
    );
    const carbs = this.calcValueFromPer100g(
      food.carbsPer100g,
      grams,
      this.safeNumber(item.carbs),
    );
    const fat = this.calcValueFromPer100g(
      food.fatPer100g,
      grams,
      this.safeNumber(item.fat),
    );

    return {
      name: item.name?.trim() || food.description,
      grams: this.round(grams),
      calories,
      protein,
      carbs,
      fat,
      source,
      matchedFood: matchedFood ?? food.description,
    };
  }

  private hasValidNutritionLabel(item: FoodAnalysisItem): boolean {
    const label = item.nutritionLabel;
    if (!label) {
      return false;
    }

    return (
      this.safeNumber(label.referenceGrams) > 0 &&
      this.safeNumber(label.calories) >= 0
    );
  }

  /**
   * Calcula macros a partir da tabela nutricional informada pelo usuário.
   * Fórmula: valor = (consumido / referência) * valor_da_tabela
   */
  private calculateFromNutritionLabel(item: FoodAnalysisItem): FoodAnalysisItem {
    const label = item.nutritionLabel!;
    const referenceGrams = this.safeNumber(label.referenceGrams);
    const consumedGrams = this.safeNumber(item.grams);
    const factor = referenceGrams > 0 ? consumedGrams / referenceGrams : 0;

    const calories = this.round(this.safeNumber(label.calories) * factor);
    const protein =
      label.protein !== undefined
        ? this.round(this.safeNumber(label.protein) * factor)
        : this.round(this.safeNumber(item.protein));
    const carbs =
      label.carbs !== undefined
        ? this.round(this.safeNumber(label.carbs) * factor)
        : this.round(this.safeNumber(item.carbs));
    const fat =
      label.fat !== undefined
        ? this.round(this.safeNumber(label.fat) * factor)
        : this.round(this.safeNumber(item.fat));

    return {
      name: item.name?.trim() || 'Alimento',
      grams: this.round(consumedGrams),
      calories,
      protein,
      carbs,
      fat,
      nutritionLabel: label,
      source: 'nutrition_label',
      matchedFood: `Tabela nutricional (${referenceGrams} g)`,
    };
  }

  private calcValueFromPer100g(
    per100g: number | null,
    grams: number,
    fallbackValue: number,
  ): number {
    if (per100g !== null && Number.isFinite(per100g)) {
      return this.round((per100g * grams) / 100);
    }

    return this.round(fallbackValue);
  }

  private estimateRecipeFromIngredients(
    item: FoodAnalysisItem,
    foods: TacoFoodEntry[],
  ): FoodAnalysisItem | null {
    const normalized = this.normalizeName(item.name);
    const template = RECIPE_TEMPLATES.find((candidate) =>
      candidate.pattern.test(normalized),
    );

    if (!template) {
      return null;
    }

    const ingredientMatches = template.ingredients
      .map((ingredient) => {
        const match = this.findBestFoodMatch(
          ingredient.name,
          foods,
          RECIPE_INGREDIENT_THRESHOLD,
        );

        if (!match) {
          return null;
        }

        return { ratio: ingredient.ratio, match };
      })
      .filter(
        (
          value,
        ): value is {
          ratio: number;
          match: FoodMatch;
        } => value !== null,
      );

    if (ingredientMatches.length < 2) {
      return null;
    }

    const ratioSum = ingredientMatches.reduce((acc, entry) => acc + entry.ratio, 0);
    if (ratioSum <= 0.5) {
      return null;
    }

    const aggregated = ingredientMatches.reduce(
      (acc, entry) => {
        const normalizedRatio = entry.ratio / ratioSum;
        acc.calories += (entry.match.food.caloriesPer100g ?? 0) * normalizedRatio;
        acc.protein += (entry.match.food.proteinPer100g ?? 0) * normalizedRatio;
        acc.carbs += (entry.match.food.carbsPer100g ?? 0) * normalizedRatio;
        acc.fat += (entry.match.food.fatPer100g ?? 0) * normalizedRatio;
        return acc;
      },
      { calories: 0, protein: 0, carbs: 0, fat: 0 },
    );

    const syntheticFood: TacoFoodEntry = {
      description: item.name,
      normalizedDescription: normalized,
      tokens: this.tokenize(normalized),
      tokenSet: new Set(this.tokenize(normalized)),
      category: null,
      caloriesPer100g: aggregated.calories,
      proteinPer100g: aggregated.protein,
      carbsPer100g: aggregated.carbs,
      fatPer100g: aggregated.fat,
    };

    const matchedFood = ingredientMatches
      .map((entry) => entry.match.food.description)
      .join(', ');

    return this.calculateFromMatchedFood(
      item,
      syntheticFood,
      'recipe_decomposition',
      matchedFood,
    );
  }

  private markAsAiEstimate(item: FoodAnalysisItem): FoodAnalysisItem {
    return {
      ...item,
      grams: this.round(this.safeNumber(item.grams)),
      calories: this.round(this.safeNumber(item.calories)),
      protein: this.round(this.safeNumber(item.protein)),
      carbs: this.round(this.safeNumber(item.carbs)),
      fat: this.round(this.safeNumber(item.fat)),
      source: item.source ?? 'ai_estimate',
      matchedFood: item.matchedFood,
    };
  }

  private safeNumber(value: number): number {
    const numeric = Number(value);
    if (!Number.isFinite(numeric)) {
      return 0;
    }
    return Math.max(0, numeric);
  }

  private sumTotals(items: FoodAnalysisItem[]): FoodAnalysisTotals {
    const totals = items.reduce(
      (acc, item) => {
        acc.calories += this.safeNumber(item.calories);
        acc.protein += this.safeNumber(item.protein);
        acc.carbs += this.safeNumber(item.carbs);
        acc.fat += this.safeNumber(item.fat);
        return acc;
      },
      { calories: 0, protein: 0, carbs: 0, fat: 0 },
    );

    return {
      calories: this.round(totals.calories),
      protein: this.round(totals.protein),
      carbs: this.round(totals.carbs),
      fat: this.round(totals.fat),
    };
  }

  private buildJustification(
    baseJustification: string,
    stats: {
      labelMatches: number;
      dbMatches: number;
      recipeMatches: number;
      aiFallbacks: number;
    },
  ): string {
    const parts: string[] = [];
    if (stats.labelMatches > 0) {
      parts.push(
        `${stats.labelMatches} item(ns) pela tabela nutricional informada`,
      );
    }
    if (stats.dbMatches > 0) {
      parts.push(`${stats.dbMatches} por correspondência TACO`);
    }
    if (stats.recipeMatches > 0) {
      parts.push(`${stats.recipeMatches} por decomposição de receita`);
    }
    if (stats.aiFallbacks > 0) {
      parts.push(`${stats.aiFallbacks} por estimativa da IA`);
    }

    const note =
      parts.length > 0
        ? `Calorias refinadas: ${parts.join(', ')}.`
        : 'Calorias refinadas com as fontes disponíveis.';

    const normalized = (baseJustification ?? '').trim();
    if (!normalized) {
      return note;
    }

    return `${normalized} ${note}`;
  }

  private round(value: number): number {
    return Math.round((value + Number.EPSILON) * 100) / 100;
  }
}
