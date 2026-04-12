import { IsEmail, IsNotEmpty } from 'class-validator';

export class ResendCodeDto {
  @IsEmail({}, { message: 'Email inválido' })
  @IsNotEmpty({ message: 'Email é obrigatório' })
  email: string;
}
