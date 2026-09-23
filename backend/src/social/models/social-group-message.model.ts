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

@Table({ tableName: 'social_group_messages', underscored: true })
export class SocialGroupMessage extends Model {
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

  @AllowNull(false)
  @Column(DataType.STRING)
  type: string;

  @AllowNull(true)
  @Column(DataType.TEXT)
  body: string | null;

  @AllowNull(true)
  @Column({ type: DataType.TEXT, field: 'image_url' })
  imageUrl: string | null;

  @ForeignKey(() => SocialGroupMessage)
  @AllowNull(true)
  @Column({ type: DataType.UUID, field: 'reply_to_id' })
  replyToId: string | null;

  @BelongsTo(() => SocialGroupMessage, { foreignKey: 'replyToId', as: 'replyTo' })
  replyTo: SocialGroupMessage | null;

  @AllowNull(true)
  @Column({ type: DataType.DATE, field: 'edited_at' })
  editedAt: Date | null;

  @AllowNull(true)
  @Column({ type: DataType.DATE, field: 'deleted_at' })
  deletedAt: Date | null;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
