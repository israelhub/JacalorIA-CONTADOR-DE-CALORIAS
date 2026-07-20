import { Type } from 'class-transformer';
import { IsArray, IsOptional, IsString, ValidateNested } from 'class-validator';
import { FoodItemInputDto } from './food-item-input.dto';

export class AnalyzeFoodDto {
  @IsOptional()
  @IsString()
  imageBase64?: string;

  @IsOptional()
  @IsString()
  mimeType?: string;

  /** Texto livre digitado pelo usuário (ex.: tabela nutricional + quanto consumiu). */
  @IsOptional()
  @IsString()
  manualText?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => FoodItemInputDto)
  items?: FoodItemInputDto[];
}