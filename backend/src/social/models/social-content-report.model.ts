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

export type SocialReportReason =
  | 'spam'
  | 'harassment'
  | 'inappropriate'
  | 'other';

export type SocialReportTargetType = 'user' | 'message';

@Table({
  tableName: 'social_content_reports',
  underscored: true,
  updatedAt: false,
})
export class SocialContentReport extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'reporter_id' })
  reporterId: string;

  @BelongsTo(() => User, { foreignKey: 'reporterId', as: 'reporter' })
  reporter: User;

  @AllowNull(false)
  @Column({ type: DataType.STRING(16), field: 'target_type' })
  targetType: SocialReportTargetType;

  @AllowNull(true)
  @Column({ type: DataType.UUID, field: 'target_user_id' })
  targetUserId: string | null;

  @AllowNull(true)
  @Column({ type: DataType.UUID, field: 'message_id' })
  messageId: string | null;

  @AllowNull(true)
  @Column({ type: DataType.UUID, field: 'group_id' })
  groupId: string | null;

  @AllowNull(false)
  @Column({ type: DataType.STRING(32), field: 'reason' })
  reason: SocialReportReason;

  @AllowNull(true)
  @Column(DataType.TEXT)
  details: string | null;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;
}
