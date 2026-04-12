import { IsEmail, IsNotEmpty, Length } from 'class-validator';

export class VerifyEmailDto {
  @IsEmail({}, { message: 'Email inválido' })
  @IsNotEmpty({ message: 'Email é obrigatório' })
  email: string;

  @IsNotEmpty({ message: 'Código é obrigatório' })
  @Length(6, 6, { message: 'Código deve ter 6 dígitos' })
  code: string;
}
