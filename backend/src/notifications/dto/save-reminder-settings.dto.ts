import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class ReminderItemDto {
  @IsString()
  @IsNotEmpty({ message: 'Id do lembrete e obrigatorio.' })
  @MaxLength(120)
  id: string;

  @IsString()
  @IsNotEmpty({ message: 'Titulo do lembrete e obrigatorio.' })
  @MaxLength(80)
  title: string;

  @IsBoolean()
  enabled: boolean;

  @IsInt()
  @Min(0)
  @Max(23)
  hour: number;

  @IsInt()
  @Min(0)
  @Max(59)
  minute: number;
}

export class SaveReminderSettingsDto {
  @IsBoolean()
  masterEnabled: boolean;

  @IsArray()
  @ArrayMaxSize(6, { message: 'Maximo de 6 lembretes.' })
  @ValidateNested({ each: true })
  @Type(() => ReminderItemDto)
  reminders: ReminderItemDto[];
}
