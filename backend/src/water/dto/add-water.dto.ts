import { IsDateString, IsInt, Max, Min } from 'class-validator';

export class AddWaterDto {
  @IsInt()
  @Min(50)
  @Max(2000)
  milliliters: number;

  @IsDateString()
  recordedAt: string;
}
