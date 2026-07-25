import {
  AllowNull,
  BelongsTo,
  Column,
  CreatedAt,
  DataType,
  Default,
  ForeignKey,
  Model,
  PrimaryKey,
  Table,
} from 'sequelize-typescript';
import { User } from '../../auth/models/user.model';
import { NotificationBroadcast } from './notification-broadcast.model';

@Table({
  tableName: 'user_notifications',
  underscored: true,
  updatedAt: false,
})
export class UserNotification extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => NotificationBroadcast)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'broadcast_id' })
  broadcastId: string;

  @BelongsTo(() => NotificationBroadcast, { onDelete: 'CASCADE' })
  broadcast: NotificationBroadcast;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string;

  @BelongsTo(() => User, { onDelete: 'CASCADE' })
  user: User;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @AllowNull(true)
  @Column({ type: DataType.DATE, field: 'read_at' })
  readAt: Date | null;

  @AllowNull(true)
  @Column({ type: DataType.DATE, field: 'dismissed_at' })
  dismissedAt: Date | null;

  @AllowNull(true)
  @Column({ type: DataType.DATE, field: 'delivered_in_app_at' })
  deliveredInAppAt: Date | null;
}
