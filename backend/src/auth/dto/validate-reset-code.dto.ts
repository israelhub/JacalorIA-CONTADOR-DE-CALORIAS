import { IsEmail, IsNotEmpty, Length } from 'class-validator';

export class ValidateResetCodeDto {
  @IsEmail({}, { message: 'Email invalido' })
  @IsNotEmpty({ message: 'Email e obrigatorio' })
  email: string;

  @IsNotEmpty({ message: 'Codigo e obrigatorio' })
  @Length(6, 6, { message: 'Codigo deve ter 6 digitos' })
  code: string;
}

