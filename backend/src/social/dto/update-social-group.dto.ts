import { IsBoolean, IsIn, IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

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
  @IsIn(['offensive', 'daily_goal', 'xp', 'group_streak', 'goal_average'])
  competitionType?: string;

  @IsOptional()
  @IsString()
  @IsIn(['salad', 'muscle', 'fire', 'trophy', 'rocket', 'apple', 'avocado'])
  iconKey?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  durationDays?: number;

  @IsOptional()
  @IsBoolean()
  isPublic?: boolean;
}
