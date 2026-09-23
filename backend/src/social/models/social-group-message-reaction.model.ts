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
import { SocialGroupMessage } from './social-group-message.model';

@Table({
  tableName: 'social_group_message_reactions',
  underscored: true,
  updatedAt: false,
  indexes: [{ unique: true, fields: ['message_id', 'user_id'] }],
})
export class SocialGroupMessageReaction extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => SocialGroupMessage)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'message_id' })
  messageId: string;

  @BelongsTo(() => SocialGroupMessage, {
    foreignKey: 'messageId',
    as: 'message',
  })
  message: SocialGroupMessage;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string;

  @BelongsTo(() => User, { foreignKey: 'userId', as: 'user' })
  user: User;

  @AllowNull(false)
  @Column({ type: DataType.STRING, field: 'emoji_id' })
  emojiId: string;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;
}
