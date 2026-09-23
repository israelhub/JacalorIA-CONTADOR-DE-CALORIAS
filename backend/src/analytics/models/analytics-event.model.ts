import {
  Table,
  Column,
  Model,
  DataType,
  PrimaryKey,
  Default,
  AllowNull,
  ForeignKey,
  BelongsTo,
  CreatedAt,
} from 'sequelize-typescript';
import { User } from '../../auth/models/user.model';

@Table({
  tableName: 'analytics_events',
  underscored: true,
  updatedAt: false,
})
export class AnalyticsEvent extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => User)
  @AllowNull(true)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string | null;

  @AllowNull(false)
  @Column({ type: DataType.STRING, field: 'event_name' })
  eventName: string;

  @AllowNull(false)
  @Default(DataType.NOW)
  @Column({ type: DataType.DATE, field: 'occurred_at' })
  occurredAt: Date;

  @AllowNull(true)
  @Column(DataType.STRING)
  platform: string | null;

  @AllowNull(true)
  @Column({ type: DataType.STRING, field: 'session_id' })
  sessionId: string | null;

  @AllowNull(false)
  @Default({})
  @Column(DataType.JSONB)
  properties: Record<string, unknown>;

  @BelongsTo(() => User)
  user: User;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;
}
