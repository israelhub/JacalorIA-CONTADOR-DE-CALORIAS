import { IsArray, IsBoolean, IsIn, IsInt, IsOptional, IsString, IsUUID, MaxLength, Min } from 'class-validator';

export class CreateSocialGroupDto {
  @IsString()
  @MaxLength(80)
  name: string;

  @IsString()
  @MaxLength(140)
  description: string;

  @IsString()
  @IsIn(['offensive', 'daily_goal', 'xp', 'group_streak'])
  competitionType: string;

  @IsString()
  @IsIn(['salad', 'muscle', 'fire', 'trophy', 'rocket', 'apple', 'avocado'])
  iconKey: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  durationDays?: number;

  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  memberUserIds?: string[];

  @IsOptional()
  @IsBoolean()
  isPublic?: boolean;
}
