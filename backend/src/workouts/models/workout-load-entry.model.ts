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
import { WorkoutExercise } from './workout-exercise.model';

@Table({ tableName: 'workout_load_entries', underscored: true })
export class WorkoutLoadEntry extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => WorkoutExercise)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'exercise_id' })
  exerciseId: string;

  @BelongsTo(() => WorkoutExercise)
  exercise: WorkoutExercise;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string;

  @BelongsTo(() => User)
  user: User;

  @AllowNull(false)
  @Column(DataType.DECIMAL)
  weight: number;

  @AllowNull(false)
  @Column({ type: DataType.DATEONLY, field: 'recorded_at' })
  recordedAt: string;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
