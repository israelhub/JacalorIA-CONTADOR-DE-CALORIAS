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

@Table({ tableName: 'social_group_members', underscored: true })
export class SocialGroupMember extends Model {
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
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string;

  @BelongsTo(() => User, { foreignKey: 'userId', as: 'user' })
  user: User;

  @Default(false)
  @Column({ type: DataType.BOOLEAN, field: 'is_leader' })
  isLeader: boolean;

  @Default(0)
  @Column(DataType.INTEGER)
  points: number;

  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'streak_days' })
  streakDays: number;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}