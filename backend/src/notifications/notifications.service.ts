import {
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { Op } from 'sequelize';
import { User } from '../auth/models/user.model';
import { MailService } from '../mail/mail.service';
import {
  CreateBroadcastDto,
  NotificationChannel,
} from './dto/create-broadcast.dto';
import { NotificationBroadcast } from './models/notification-broadcast.model';
import { UserNotification } from './models/user-notification.model';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    @InjectModel(NotificationBroadcast)
    private readonly broadcastModel: typeof NotificationBroadcast,
    @InjectModel(UserNotification)
    private readonly userNotificationModel: typeof UserNotification,
    @InjectModel(User)
    private readonly userModel: typeof User,
    private readonly mailService: MailService,
  ) {}

  private includesInbox(channel: NotificationChannel): boolean {
    return channel === 'inbox' || channel === 'both';
  }

  private includesEmail(channel: NotificationChannel): boolean {
    return channel === 'email' || channel === 'both';
  }

  async createBroadcast(dto: CreateBroadcastDto) {
    const title = dto.title.trim();
    const body = dto.body.trim();
    const channel = dto.channel;

    const users = await this.userModel.findAll({
      attributes: ['id', 'email', 'name'],
      order: [['created_at', 'ASC']],
    });

    const broadcast = await this.broadcastModel.create({
      title,
      body,
      channel,
      audience: 'all',
      recipientCount: users.length,
      emailSentCount: 0,
      emailFailedCount: 0,
    });

    if (this.includesInbox(channel) && users.length > 0) {
      const rows = users.map((user) => ({
        broadcastId: broadcast.id,
        userId: user.id,
        createdAt: broadcast.createdAt,
      }));
      await this.userNotificationModel.bulkCreate(rows, {
        ignoreDuplicates: true,
      });
    }

    let emailSentCount = 0;
    let emailFailedCount = 0;

    if (this.includesEmail(channel)) {
      for (const user of users) {
        const email = user.email?.trim();
        if (!email) {
          emailFailedCount += 1;
          continue;
        }
        const ok = await this.mailService.sendAnnouncement({
          to: email,
          title,
          body,
          userName: user.name?.trim() || undefined,
        });
        if (ok) {
          emailSentCount += 1;
        } else {
          emailFailedCount += 1;
        }
      }

      await broadcast.update({ emailSentCount, emailFailedCount });
    }

    this.logger.log(
      `Broadcast ${broadcast.id} channel=${channel} recipients=${users.length} emailOk=${emailSentCount} emailFail=${emailFailedCount}`,
    );

    return this.toBroadcastDto(broadcast, {
      emailSentCount,
      emailFailedCount,
    });
  }

  async listBroadcasts(limit = 50) {
    const rows = await this.broadcastModel.findAll({
      order: [['created_at', 'DESC']],
      limit: Math.min(Math.max(limit, 1), 100),
    });
    return rows.map((row) => this.toBroadcastDto(row));
  }

  async getInbox(userId: string) {
    const rows = await this.userNotificationModel.findAll({
      where: {
        userId,
        dismissedAt: null,
      },
      include: [
        {
          model: NotificationBroadcast,
          required: true,
          where: {
            channel: { [Op.in]: ['inbox', 'both'] },
          },
        },
      ],
      order: [['created_at', 'DESC']],
      limit: 100,
    });

    const now = new Date();
    const pendingDelivery = rows.filter((row) => !row.deliveredInAppAt);
    if (pendingDelivery.length > 0) {
      await this.userNotificationModel.update(
        { deliveredInAppAt: now },
        {
          where: {
            id: pendingDelivery.map((row) => row.id),
            deliveredInAppAt: null,
          },
        },
      );
    }

    return rows.map((row) => ({
      id: row.id,
      broadcastId: row.broadcastId,
      title: row.broadcast.title,
      body: row.broadcast.body,
      createdAt: row.createdAt.toISOString(),
      readAt: row.readAt ? row.readAt.toISOString() : null,
      source: 'catalog',
      sourceKey: `broadcast:${row.broadcastId}`,
    }));
  }

  async markRead(userId: string, notificationId: string) {
    const row = await this.userNotificationModel.findOne({
      where: { id: notificationId, userId, dismissedAt: null },
    });
    if (!row) {
      throw new NotFoundException('Notificacao nao encontrada');
    }
    if (!row.readAt) {
      await row.update({ readAt: new Date() });
    }
    return { success: true as const };
  }

  async dismiss(userId: string, notificationId: string) {
    const row = await this.userNotificationModel.findOne({
      where: { id: notificationId, userId },
    });
    if (!row) {
      throw new NotFoundException('Notificacao nao encontrada');
    }
    const now = new Date();
    await row.update({
      dismissedAt: now,
      readAt: row.readAt ?? now,
    });
    return { success: true as const };
  }

  private toBroadcastDto(
    row: NotificationBroadcast,
    overrides?: { emailSentCount?: number; emailFailedCount?: number },
  ) {
    return {
      id: row.id,
      title: row.title,
      body: row.body,
      channel: row.channel,
      audience: row.audience,
      recipientCount: row.recipientCount,
      emailSentCount: overrides?.emailSentCount ?? row.emailSentCount,
      emailFailedCount: overrides?.emailFailedCount ?? row.emailFailedCount,
      createdAt: row.createdAt.toISOString(),
    };
  }
}
