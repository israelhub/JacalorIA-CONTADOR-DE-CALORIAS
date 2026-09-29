import { IsString } from 'class-validator';

export class PurchaseAvatarBackgroundDto {
  @IsString()
  backgroundId: string;
}
