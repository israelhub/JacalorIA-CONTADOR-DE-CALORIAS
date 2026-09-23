import { IsString } from 'class-validator';

export class PurchaseJacaEmojiDto {
  @IsString()
  emojiId: string;
}
