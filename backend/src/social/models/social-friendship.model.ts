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

@Table({ tableName: 'social_friendships', underscored: true })
export class SocialFriendship extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'user_low_id' })
  userLowId: string;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'user_high_id' })
  userHighId: string;

  @BelongsTo(() => User, { foreignKey: 'userLowId', as: 'userLow' })
  userLow: User;

  @BelongsTo(() => User, { foreignKey: 'userHighId', as: 'userHigh' })
  userHigh: User;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}

