import {
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export const SUPPORT_SUBJECT_TYPES = ['bug', 'suggestion'] as const;
export type SupportSubjectType = (typeof SUPPORT_SUBJECT_TYPES)[number];

export class CreateSupportMessageDto {
  @IsIn(SUPPORT_SUBJECT_TYPES, {
    message: 'Tipo de assunto invalido. Use bug ou suggestion.',
  })
  subjectType: SupportSubjectType;

  @IsString()
  @IsNotEmpty({ message: 'Descricao e obrigatoria.' })
  @MinLength(10, { message: 'Descricao deve ter pelo menos 10 caracteres.' })
  @MaxLength(5000, { message: 'Descricao deve ter no maximo 5000 caracteres.' })
  description: string;

  @IsOptional()
  @IsEmail({}, { message: 'Email invalido.' })
  email?: string;
}
