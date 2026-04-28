import { IsString, IsNumber, IsOptional, IsArray } from 'class-validator';

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
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsArray()
  analysisItems?: any[];
}
