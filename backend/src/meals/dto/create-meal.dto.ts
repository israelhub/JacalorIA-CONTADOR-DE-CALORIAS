import { IsString, IsNumber, IsOptional, IsArray, IsIn } from 'class-validator';
import { MealType } from '../models/meal.model';

export class CreateMealDto {
  @IsString()
  title: string;

  @IsString()
  description: string;

  @IsNumber()
  calories: number;

  @IsNumber()
  protein: number;

  @IsNumber()
  carbs: number;

  @IsNumber()
  fat: number;

  @IsOptional()
  @IsString()
  timeLabel?: string;

  @IsOptional()
  @IsIn([
    MealType.Breakfast,
    MealType.Lunch,
    MealType.Dinner,
    MealType.Free,
  ])
  mealType?: MealType;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsArray()
  analysisItems?: any[];
}
