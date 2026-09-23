import {
  IsIn,
  IsNotEmpty,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export const NOTIFICATION_CHANNELS = ['inbox', 'email', 'both'] as const;
export type NotificationChannel = (typeof NOTIFICATION_CHANNELS)[number];

export class CreateBroadcastDto {
  @IsString()
  @IsNotEmpty({ message: 'Titulo e obrigatorio.' })
  @MinLength(2, { message: 'Titulo deve ter pelo menos 2 caracteres.' })
  @MaxLength(200, { message: 'Titulo deve ter no maximo 200 caracteres.' })
  title: string;

  @IsString()
  @IsNotEmpty({ message: 'Mensagem e obrigatoria.' })
  @MinLength(2, { message: 'Mensagem deve ter pelo menos 2 caracteres.' })
  @MaxLength(5000, { message: 'Mensagem deve ter no maximo 5000 caracteres.' })
  body: string;

  @IsIn(NOTIFICATION_CHANNELS, {
    message: 'Canal invalido. Use inbox, email ou both.',
  })
  channel: NotificationChannel;
}
