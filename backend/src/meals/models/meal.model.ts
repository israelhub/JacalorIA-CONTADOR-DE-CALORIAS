import {
  Table,
  Column,
  Model,
  DataType,
  CreatedAt,
  UpdatedAt,
  Default,
  PrimaryKey,
  ForeignKey,
  BelongsTo,
  AllowNull,
} from 'sequelize-typescript';
import { User } from '../../auth/models/user.model';

@Table({ tableName: 'meals', underscored: true })
export class Meal extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => User)
  @AllowNull(true)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string | null;

  @BelongsTo(() => User)
  user: User;

  @AllowNull(false)
  @Column(DataType.STRING)
  title: string;

  @AllowNull(false)
  @Column(DataType.TEXT)
  description: string;

  @AllowNull(false)
  @Column(DataType.DECIMAL)
  calories: number;

  @AllowNull(false)
  @Column(DataType.DECIMAL)
  protein: number;

  @AllowNull(false)
  @Column(DataType.DECIMAL)
  carbs: number;

  @AllowNull(false)
  @Column(DataType.DECIMAL)
  fat: number;

  @AllowNull(true)
  @Column({ type: DataType.STRING, field: 'time_label' })
  timeLabel: string | null;

  @AllowNull(true)
  @Column({ type: DataType.STRING, field: 'image_url' })
  imageUrl: string | null;

  @AllowNull(true)
  @Column({ type: DataType.JSONB, field: 'analysis_items' })
  analysisItems: any;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
