import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateRoutineDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  name: string;
}
