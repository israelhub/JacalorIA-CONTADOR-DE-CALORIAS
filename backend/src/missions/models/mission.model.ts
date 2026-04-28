import {
  Table,
  Column,
  Model,
  DataType,
  CreatedAt,
  UpdatedAt,
  Default,
  PrimaryKey,
  AllowNull,
  Unique,
} from 'sequelize-typescript';

export type MissionType = 'daily' | 'weekly' | 'monthly';
export type MissionAccent = 'action' | 'accent' | 'challenge';

@Table({ tableName: 'missions', underscored: true })
export class Mission extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @Unique
  @AllowNull(false)
  @Column(DataType.STRING)
  key: string;

  @AllowNull(false)
  @Column(DataType.STRING)
  type: MissionType;

  @AllowNull(false)
  @Column(DataType.STRING)
  title: string;

  @AllowNull(false)
  @Column(DataType.STRING)
  description: string;

  @AllowNull(false)
  @Default(1)
  @Column({ type: DataType.INTEGER, field: 'target_value' })
  targetValue: number;

  @AllowNull(false)
  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'reward_gold' })
  rewardGold: number;

  @AllowNull(false)
  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'reward_xp' })
  rewardXp: number;

  @AllowNull(false)
  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'sort_order' })
  sortOrder: number;

  @AllowNull(false)
  @Default('action')
  @Column(DataType.STRING)
  accent: MissionAccent;

  @AllowNull(false)
  @Default(true)
  @Column({ type: DataType.BOOLEAN, field: 'is_active' })
  isActive: boolean;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
