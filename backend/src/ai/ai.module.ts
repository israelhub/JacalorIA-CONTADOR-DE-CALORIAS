import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { FOOD_ANALYSIS_PROVIDER } from './providers/food-analysis.provider';
import { FoodAnalysisProviderImpl } from './providers/gemini-food-analysis.provider';

@Module({
  controllers: [AiController],
  providers: [
    AiService,
    FoodAnalysisProviderImpl,
    {
      provide: FOOD_ANALYSIS_PROVIDER,
      inject: [ConfigService, FoodAnalysisProviderImpl],
      useFactory: (
        configService: ConfigService,
        foodAnalysisProvider: FoodAnalysisProviderImpl,
      ) => {
        const provider = configService.get<string>('AI_PROVIDER', 'gemini');

        switch (provider) {
          case 'gemini':
          default:
            return foodAnalysisProvider;
        }
      },
    },
  ],
  imports: [ConfigModule],
})
export class AiModule {}