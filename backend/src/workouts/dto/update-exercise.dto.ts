import {
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class UpdateExerciseDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  name?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  sets?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  reps?: number;
}
