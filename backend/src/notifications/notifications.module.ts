import { Module } from '@nestjs/common';
import { SequelizeModule } from '@nestjs/sequelize';
import { AuthModule } from '../auth/auth.module';
import { MailModule } from '../mail/mail.module';
import { User } from '../auth/models/user.model';
import { DashboardTokenGuard } from '../analytics/guards/dashboard-token.guard';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { NotificationBroadcast } from './models/notification-broadcast.model';
import { UserNotification } from './models/user-notification.model';

@Module({
  imports: [
    AuthModule,
    MailModule,
    SequelizeModule.forFeature([
      NotificationBroadcast,
      UserNotification,
      User,
    ]),
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, DashboardTokenGuard],
  exports: [NotificationsService],
})
export class NotificationsModule {}
