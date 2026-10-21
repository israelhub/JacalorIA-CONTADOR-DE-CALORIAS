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

@Table({
  tableName: 'social_user_blocks',
  underscored: true,
  updatedAt: false,
})
export class SocialUserBlock extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'blocker_id' })
  blockerId: string;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'blocked_id' })
  blockedId: string;

  @BelongsTo(() => User, { foreignKey: 'blockerId', as: 'blocker' })
  blocker: User;

  @BelongsTo(() => User, { foreignKey: 'blockedId', as: 'blocked' })
  blocked: User;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;
}
