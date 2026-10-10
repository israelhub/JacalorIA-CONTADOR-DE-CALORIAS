import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class ImportWorkoutsDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(12000)
  text: string;
}
