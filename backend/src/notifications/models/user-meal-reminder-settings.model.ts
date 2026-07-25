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

export interface MealReminderItem {
  id: string;
  title: string;
  enabled: boolean;
  hour: number;
  minute: number;
}

@Table({
  tableName: 'user_meal_reminder_settings',
  underscored: true,
})
export class UserMealReminderSettings extends Model {
  @PrimaryKey
  @ForeignKey(() => User)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string;

  @BelongsTo(() => User, { onDelete: 'CASCADE' })
  user: User;

  @AllowNull(false)
  @Default(true)
  @Column({ type: DataType.BOOLEAN, field: 'master_enabled' })
  masterEnabled: boolean;

  @AllowNull(false)
  @Default([])
  @Column(DataType.JSONB)
  reminders: MealReminderItem[];

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
