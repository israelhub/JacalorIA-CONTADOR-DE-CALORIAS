import { IsOptional, IsString, IsNumber, IsDateString, Min, IsBoolean } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  birthDate?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  weight?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  height?: number;

  @IsOptional()
  @IsString()
  weightUnit?: string;

  @IsOptional()
  @IsString()
  heightUnit?: string;

  @IsOptional()
  @IsString()
  sex?: string;

  @IsOptional()
  @IsString()
  objective?: string;

  @IsOptional()
  @IsString()
  activityLevel?: string;

  @IsOptional()
  @IsNumber()
  dailyCalorieGoal?: number;

  @IsOptional()
  @IsNumber()
  dailyProteinGoal?: number;

  @IsOptional()
  @IsNumber()
  dailyCarbsGoal?: number;

  @IsOptional()
  @IsNumber()
  dailyFatGoal?: number;

  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @IsOptional()
  @IsBoolean()
  hideMissionsGuideMe?: boolean;

  @IsOptional()
  @IsBoolean()
  hideSocialGuideMe?: boolean;
}
