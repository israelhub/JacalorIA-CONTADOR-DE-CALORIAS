import {
  BelongsTo,
  Column,
  CreatedAt,
  DataType,
  ForeignKey,
  Model,
  Table,
  UpdatedAt,
} from 'sequelize-typescript';
import { User } from '../../auth/models/user.model';

export type SocialFriendRequestStatus = 'pending' | 'accepted' | 'rejected';

@Table({
  tableName: 'social_friend_requests',
  underscored: true,
  indexes: [
    {
      unique: true,
      fields: ['requester_id', 'recipient_id'],
    },
    {
      fields: ['recipient_id', 'status', 'created_at'],
    },
  ],
})
export class SocialFriendRequest extends Model {
  @Column({ type: DataType.UUID, defaultValue: DataType.UUIDV4, primaryKey: true })
  id: string;

  @ForeignKey(() => User)
  @Column({ type: DataType.UUID, allowNull: false, field: 'requester_id' })
  requesterId: string;

  @BelongsTo(() => User, { foreignKey: 'requesterId', as: 'requester' })
  requester?: User;

  @ForeignKey(() => User)
  @Column({ type: DataType.UUID, allowNull: false, field: 'recipient_id' })
  recipientId: string;

  @BelongsTo(() => User, { foreignKey: 'recipientId', as: 'recipient' })
  recipient?: User;

  @Column({
    type: DataType.ENUM('pending', 'accepted', 'rejected'),
    allowNull: false,
    defaultValue: 'pending',
  })
  status: SocialFriendRequestStatus;

  @Column({ type: DataType.DATE, allowNull: true, field: 'responded_at' })
  respondedAt?: Date | null;

  @CreatedAt
  createdAt: Date;

  @UpdatedAt
  updatedAt: Date;
}
