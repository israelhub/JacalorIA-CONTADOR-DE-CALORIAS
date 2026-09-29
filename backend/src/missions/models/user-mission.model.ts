import {
  AllowNull,
  Column,
  CreatedAt,
  DataType,
  Default,
  Model,
  PrimaryKey,
  Table,
  UpdatedAt,
} from 'sequelize-typescript';

export type UserMissionStatus = 'in_progress' | 'completed';

@Table({
  tableName: 'user_missions',
  underscored: true,
  indexes: [
    {
      name: 'uniq_user_missions_period',
      unique: true,
      fields: ['user_id', 'mission_id', 'period_key'],
    },
    {
      name: 'idx_user_missions_user_status',
      fields: ['user_id', 'status'],
    },
  ],
})
export class UserMission extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string;

  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'mission_id' })
  missionId: string;

  @AllowNull(false)
  @Column({ type: DataType.STRING, field: 'mission_key' })
  missionKey: string;

  @AllowNull(false)
  @Column({ type: DataType.STRING, field: 'period_key' })
  periodKey: string;

  @AllowNull(false)
  @Default('in_progress')
  @Column(DataType.STRING)
  status: UserMissionStatus;

  @AllowNull(false)
  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'progress_current' })
  progressCurrent: number;

  @AllowNull(false)
  @Default(1)
  @Column({ type: DataType.INTEGER, field: 'progress_target' })
  progressTarget: number;

  @AllowNull(true)
  @Column({ type: DataType.DATE, field: 'completed_at' })
  completedAt: Date | null;

  @AllowNull(true)
  @Column({ type: DataType.DATE, field: 'reward_credited_at' })
  rewardCreditedAt: Date | null;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
