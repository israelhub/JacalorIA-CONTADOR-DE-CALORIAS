import {
  AllowNull,
  Column,
  CreatedAt,
  DataType,
  Default,
  HasMany,
  Model,
  PrimaryKey,
  Table,
} from 'sequelize-typescript';
import type { NotificationChannel } from '../dto/create-broadcast.dto';
import { UserNotification } from './user-notification.model';

@Table({
  tableName: 'notification_broadcasts',
  underscored: true,
  updatedAt: false,
})
export class NotificationBroadcast extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @AllowNull(false)
  @Column(DataType.STRING(200))
  title: string;

  @AllowNull(false)
  @Column(DataType.TEXT)
  body: string;

  @AllowNull(false)
  @Column(DataType.STRING(16))
  channel: NotificationChannel;

  @AllowNull(false)
  @Default('all')
  @Column(DataType.STRING(16))
  audience: string;

  @AllowNull(false)
  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'recipient_count' })
  recipientCount: number;

  @AllowNull(false)
  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'email_sent_count' })
  emailSentCount: number;

  @AllowNull(false)
  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'email_failed_count' })
  emailFailedCount: number;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @HasMany(() => UserNotification)
  deliveries: UserNotification[];
}
