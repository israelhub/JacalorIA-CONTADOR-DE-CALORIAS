import { IsInt, IsNotEmpty, IsString, Max, MaxLength, Min } from 'class-validator';

export class CreateExerciseDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  name: string;

  @IsInt()
  @Min(1)
  @Max(20)
  sets: number;

  @IsInt()
  @Min(1)
  @Max(100)
  reps: number;
}
