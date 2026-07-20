import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { MailModule } from '../mail/mail.module';
import { SupportController } from './support.controller';
import { SupportService } from './support.service';

@Module({
  imports: [MailModule, AuthModule],
  controllers: [SupportController],
  providers: [SupportService],
})
export class SupportModule {}
