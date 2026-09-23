import { IsIn, IsOptional, IsString, IsUUID, MaxLength, ValidateIf } from 'class-validator';

export class SendGroupMessageDto {
  @IsIn(['text', 'image', 'emoji'])
  type: 'text' | 'image' | 'emoji';

  @ValidateIf((dto: SendGroupMessageDto) => dto.type === 'text' || dto.type === 'emoji')
  @IsString()
  @MaxLength(2000)
  body?: string;

  @ValidateIf((dto: SendGroupMessageDto) => dto.type === 'image')
  @IsString()
  @MaxLength(2048)
  imageUrl?: string;

  @IsOptional()
  @IsUUID('4')
  replyToId?: string;
}
