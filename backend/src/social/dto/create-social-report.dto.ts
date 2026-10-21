import { IsIn, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateSocialReportDto {
  @IsIn(['spam', 'harassment', 'inappropriate', 'other'])
  reason: 'spam' | 'harassment' | 'inappropriate' | 'other';

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  details?: string;

  @IsOptional()
  @IsUUID()
  targetUserId?: string;

  @IsOptional()
  @IsUUID()
  messageId?: string;

  @IsOptional()
  @IsUUID()
  groupId?: string;
}
