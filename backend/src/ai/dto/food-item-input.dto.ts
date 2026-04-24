import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, Min } from 'class-validator';

export class FoodItemInputDto {
  @IsString()
  @IsNotEmpty()
  name!: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  grams!: number;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  unit?: string;
}