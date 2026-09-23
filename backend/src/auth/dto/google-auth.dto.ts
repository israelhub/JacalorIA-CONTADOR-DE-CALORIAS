import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class GoogleAuthDto {
  @IsOptional()
  @IsString({ message: 'idToken deve ser texto' })
  idToken?: string;

  @IsOptional()
  @IsString({ message: 'accessToken deve ser texto' })
  accessToken?: string;

  @IsNotEmpty({ message: 'idToken ou accessToken e obrigatorio' })
  get tokenForValidation(): string {
    return this.idToken ?? this.accessToken ?? '';
  }
}
