import { IsOptional, Matches } from 'class-validator';

export class GetMonthlyPerformanceDto {
  @IsOptional()
  @Matches(/^\d{4}-\d{2}$/, {
    message: 'month deve estar no formato YYYY-MM',
  })
  month?: string;
}
