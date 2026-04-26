import { IsIn, IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateSocialGroupDto {
  @IsString()
  @MaxLength(80)
  name: string;

  @IsString()
  @MaxLength(140)
  description: string;

  @IsString()
  @IsIn(['offensive', 'daily_goal', 'calories', 'xp'])
  competitionType: string;

  @IsString()
  @IsIn(['salad', 'muscle', 'fire', 'trophy', 'rocket', 'apple', 'avocado'])
  iconKey: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  durationDays?: number;
}