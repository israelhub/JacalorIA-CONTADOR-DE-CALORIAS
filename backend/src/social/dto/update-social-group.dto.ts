import { IsIn, IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class UpdateSocialGroupDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(140)
  description?: string;

  @IsOptional()
  @IsString()
  @IsIn(['offensive', 'daily_goal', 'calories', 'xp'])
  competitionType?: string;

  @IsOptional()
  @IsString()
  @IsIn(['salad', 'muscle', 'fire', 'trophy', 'rocket', 'apple', 'avocado'])
  iconKey?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  durationDays?: number;
}