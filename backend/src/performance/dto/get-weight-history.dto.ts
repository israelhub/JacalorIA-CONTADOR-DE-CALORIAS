import { IsIn, IsOptional, Matches } from 'class-validator';

const presets = ['7', '15', '30', '60', '90', '180', '365', 'custom'] as const;

export class GetWeightHistoryDto {
  @IsOptional()
  @IsIn(presets, {
    message: 'period deve ser 7, 15, 30, 60, 90, 180, 365 ou custom',
  })
  period?: (typeof presets)[number];

  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'startDate deve estar no formato YYYY-MM-DD',
  })
  startDate?: string;

  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'endDate deve estar no formato YYYY-MM-DD',
  })
  endDate?: string;
}
