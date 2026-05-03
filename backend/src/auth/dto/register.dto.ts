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
  @Matches(/\d/, { message: 'Senha deve conter ao menos 1 numero' })
  password: string;
}
