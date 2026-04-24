import { AnalyzeFoodDto } from '../dto/analyze-food.dto';

export type FoodAnalysisItem = {
  name: string;
  grams: number;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
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

export interface FoodAnalysisProvider {
  analyzeFood(analyzeFoodDto: AnalyzeFoodDto): Promise<FoodAnalysisResponse>;
}

export const FOOD_ANALYSIS_PROVIDER = 'FOOD_ANALYSIS_PROVIDER';