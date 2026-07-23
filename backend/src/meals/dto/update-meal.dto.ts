import { IsArray, IsIn, IsNumber, IsOptional, IsString } from 'class-validator';
import { MealType } from '../models/meal.model';

export class UpdateMealDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsNumber()
  calories?: number;

  @IsOptional()
  @IsNumber()
  protein?: number;

  @IsOptional()
  @IsNumber()
  carbs?: number;

  @IsOptional()
  @IsNumber()
  fat?: number;

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
