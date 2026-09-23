import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { User } from '../auth/models/user.model';
import { AuthModule } from '../auth/auth.module';
import { AnalyticsModule } from '../analytics/analytics.module';
import { MailModule } from '../mail/mail.module';
import { SupportController } from './support.controller';
import { SupportService } from './support.service';
import { SupportMessage } from './models/support-message.model';

@Module({
  imports: [
    MailModule,
    AuthModule,
    AnalyticsModule,
    SequelizeModule.forFeature([User, SupportMessage]),
  ],
  controllers: [SupportController],
  providers: [SupportService],
  exports: [SupportService],
})
export class SupportModule {}
