import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  Matches,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  @IsOptional()
  @IsNotEmpty({ message: 'Nome e obrigatorio' })
  name?: string;

  @IsEmail({}, { message: 'Email invalido' })
  @IsNotEmpty({ message: 'Email e obrigatorio' })
  email: string;

  @IsNotEmpty({ message: 'Senha e obrigatoria' })
  @MinLength(8, { message: 'Senha deve ter no minimo 8 caracteres' })
  @Matches(/[A-Z]/, { message: 'Senha deve conter ao menos 1 letra maiuscula' })
  @Matches(/[a-z]/, { message: 'Senha deve conter ao menos 1 letra minuscula' })
  @Matches(/\d/, { message: 'Senha deve conter ao menos 1 numero' })
  @Matches(/[^A-Za-z0-9]/, {
    message: 'Senha deve conter ao menos 1 caractere especial',
  })
  password: string;
}
