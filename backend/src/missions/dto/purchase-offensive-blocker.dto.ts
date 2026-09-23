import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class PurchaseOffensiveBlockerDto {
  @IsString()
  blockerId: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(99)
  quantity?: number;
}
