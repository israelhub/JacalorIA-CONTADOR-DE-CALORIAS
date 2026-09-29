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
import type { FoodAnalysisResponse } from '../providers/food-analysis.provider';

@Table({
  tableName: 'food_image_analyses',
  underscored: true,
  indexes: [
    {
      name: 'food_image_analyses_user_hash_unique',
      unique: true,
      fields: ['user_id', 'content_hash'],
    },
  ],
})
export class FoodImageAnalysis extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string;

  @BelongsTo(() => User, { onDelete: 'CASCADE' })
  user: User;

  @AllowNull(false)
  @Column({ type: DataType.STRING(64), field: 'content_hash' })
  contentHash: string;

  @AllowNull(false)
  @Column(DataType.JSONB)
  result: FoodAnalysisResponse;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
