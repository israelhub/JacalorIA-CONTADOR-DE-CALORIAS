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
  UpdatedAt,
} from 'sequelize-typescript';
import { User } from '../../auth/models/user.model';
import { SocialGroup } from './social-group.model';

@Table({ tableName: 'social_group_activities', underscored: true })
export class SocialGroupActivity extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => SocialGroup)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'group_id' })
  groupId: string;

  @BelongsTo(() => SocialGroup, { foreignKey: 'groupId', as: 'group' })
  group: SocialGroup;

  @ForeignKey(() => User)
  @AllowNull(true)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string | null;

  @BelongsTo(() => User, { foreignKey: 'userId', as: 'user' })
  user: User | null;

  @AllowNull(false)
  @Column({ type: DataType.STRING, field: 'activity_type' })
  activityType: string;

  @AllowNull(false)
  @Column(DataType.STRING)
  message: string;

  @AllowNull(true)
  @Column(DataType.JSONB)
  metadata: unknown;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}