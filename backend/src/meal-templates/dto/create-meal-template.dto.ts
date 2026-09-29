import { IsString, IsNumber, IsOptional, IsArray } from 'class-validator';

export class CreateMealTemplateDto {
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
  imageUrl?: string;

  @IsOptional()
  @IsArray()
  analysisItems?: any[];
}
