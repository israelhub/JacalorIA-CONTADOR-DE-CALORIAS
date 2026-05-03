import { IsEmail, IsNotEmpty, Length, Matches, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @IsEmail({}, { message: 'Email invalido' })
  @IsNotEmpty({ message: 'Email e obrigatorio' })
  email: string;

  @IsNotEmpty({ message: 'Codigo e obrigatorio' })
  @Length(6, 6, { message: 'Codigo deve ter 6 digitos' })
  code: string;

  @IsNotEmpty({ message: 'Nova senha e obrigatoria' })
  @MinLength(8, { message: 'Nova senha deve ter no minimo 8 caracteres' })
  @Matches(/\d/, { message: 'Nova senha deve conter ao menos 1 numero' })
  newPassword: string;
}
