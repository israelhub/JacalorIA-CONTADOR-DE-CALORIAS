import {
  AllowNull,
  BelongsTo,
  Column,
  CreatedAt,
  DataType,
  Default,
  ForeignKey,
  HasMany,
  Model,
  PrimaryKey,
  Table,
  UpdatedAt,
} from 'sequelize-typescript';
import { User } from '../../auth/models/user.model';
import { SocialGroupActivity } from './social-group-activity.model';
import { SocialGroupMember } from './social-group-member.model';

@Table({ tableName: 'social_groups', underscored: true })
export class SocialGroup extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'owner_id' })
  ownerId: string;

  @BelongsTo(() => User, { foreignKey: 'ownerId', as: 'owner' })
  owner: User;

  @AllowNull(false)
  @Column(DataType.STRING)
  name: string;

  @AllowNull(false)
  @Column(DataType.TEXT)
  description: string;

  @AllowNull(false)
  @Default('offensive')
  @Column({ type: DataType.STRING, field: 'competition_type' })
  competitionType: string;

  @AllowNull(false)
  @Default('salad')
  @Column({ type: DataType.STRING, field: 'icon_key' })
  iconKey: string;

  @AllowNull(false)
  @Default(7)
  @Column({ type: DataType.INTEGER, field: 'duration_days' })
  durationDays: number;

  @AllowNull(false)
  @Column({ type: DataType.STRING, field: 'invite_code' })
  inviteCode: string;

  @AllowNull(false)
  @Column({ type: DataType.DATE, field: 'starts_at' })
  startsAt: Date;

  @AllowNull(false)
  @Column({ type: DataType.DATE, field: 'ends_at' })
  endsAt: Date;

  @HasMany(() => SocialGroupMember, { as: 'members', foreignKey: 'groupId' })
  members: SocialGroupMember[];

  @HasMany(() => SocialGroupActivity, { as: 'activities', foreignKey: 'groupId' })
  activities: SocialGroupActivity[];

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}