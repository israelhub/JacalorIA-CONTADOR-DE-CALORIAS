import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateRoutineDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  name?: string;
}
