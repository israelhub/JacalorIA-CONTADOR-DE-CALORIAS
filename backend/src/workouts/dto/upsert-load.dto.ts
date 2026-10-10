import { IsDateString, IsNumber, Max, Min } from 'class-validator';

export class UpsertLoadDto {
  @IsNumber()
  @Min(0)
  @Max(1000)
  weight: number;

  @IsDateString()
  recordedAt: string;
}
