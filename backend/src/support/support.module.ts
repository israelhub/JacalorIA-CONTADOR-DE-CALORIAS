import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { User } from '../auth/models/user.model';
import { AuthModule } from '../auth/auth.module';
import { MailModule } from '../mail/mail.module';
import { SupportController } from './support.controller';
import { SupportService } from './support.service';

@Module({
  imports: [MailModule, AuthModule, SequelizeModule.forFeature([User])],
  controllers: [SupportController],
  providers: [SupportService],
})
export class SupportModule {}
