import { IsString } from 'class-validator';

export class PurchaseAvatarFrameDto {
  @IsString()
  frameId: string;
}

