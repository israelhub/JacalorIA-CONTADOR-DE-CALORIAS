import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './auth/auth.module';
import { MailModule } from './mail/mail.module';
import { AiModule } from './ai/ai.module';
import { MealsModule } from './meals/meals.module';
import { MealTemplatesModule } from './meal-templates/meal-templates.module';
import { PerformanceModule } from './performance/performance.module';
import { MissionsModule } from './missions/missions.module';
import { SocialModule } from './social/social.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { SupportModule } from './support/support.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    DatabaseModule,
    AuthModule,
    MailModule,
    AiModule,
    MealsModule,
    MealTemplatesModule,
    PerformanceModule,
    MissionsModule,
    SocialModule,
    AnalyticsModule,
    SupportModule,
  ],
})
export class AppModule {}
