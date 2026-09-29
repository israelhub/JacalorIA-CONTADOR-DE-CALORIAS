import { AnalyzeFoodDto } from '../dto/analyze-food.dto';

export type FoodNutritionLabel = {
  /** Porção de referência da tabela (ex.: 100). */
  referenceGrams: number;
  calories: number;
  protein?: number;
  carbs?: number;
  fat?: number;
};

export type FoodAnalysisItem = {
  name: string;
  grams: number;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  /** Dados da tabela nutricional informados pelo usuário; o sistema calcula a proporção. */
  nutritionLabel?: FoodNutritionLabel;
  source?:
    | 'nutrition_label'
    | 'taco_db'
    | 'recipe_decomposition'
    | 'ai_estimate';
  matchedFood?: string;
};

export type FoodAnalysisTotals = {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
};

export type FoodAnalysisResponse = {
  items: FoodAnalysisItem[];
  totals: FoodAnalysisTotals;
  justification: string;
};

export type FoodAnalysisProviderMeta = {
  model: string;
  attempts: number;
  failedModels: string[];
  promptTokens: number | null;
  outputTokens: number | null;
  totalTokens: number | null;
};

export type FoodAnalysisProviderResult = {
  analysis: FoodAnalysisResponse;
  meta: FoodAnalysisProviderMeta;
};

export interface FoodAnalysisProvider {
  analyzeFood(analyzeFoodDto: AnalyzeFoodDto): Promise<FoodAnalysisProviderResult>;
}

export const FOOD_ANALYSIS_PROVIDER = 'FOOD_ANALYSIS_PROVIDER';
