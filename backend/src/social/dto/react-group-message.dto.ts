import { IsIn, IsString } from 'class-validator';
import { JACA_EMOJI_IDS } from '../constants/jaca-emojis';

export class ReactGroupMessageDto {
  @IsString()
  @IsIn([...JACA_EMOJI_IDS])
  emojiId: string;
}
