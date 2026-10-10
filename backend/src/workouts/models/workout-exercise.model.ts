import {
  AllowNull,
  BelongsTo,
  Column,
  CreatedAt,
  DataType,
  Default,
  ForeignKey,
  HasMany,
  Model,
  PrimaryKey,
  Table,
  UpdatedAt,
} from 'sequelize-typescript';
import { User } from '../../auth/models/user.model';
import { WorkoutRoutine } from './workout-routine.model';
import { WorkoutLoadEntry } from './workout-load-entry.model';

@Table({ tableName: 'workout_exercises', underscored: true })
export class WorkoutExercise extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => WorkoutRoutine)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'routine_id' })
  routineId: string;

  @BelongsTo(() => WorkoutRoutine)
  routine: WorkoutRoutine;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string;

  @BelongsTo(() => User)
  user: User;

  @AllowNull(false)
  @Column(DataType.STRING)
  name: string;

  @Default(3)
  @Column(DataType.INTEGER)
  sets: number;

  @Default(10)
  @Column(DataType.INTEGER)
  reps: number;

  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'sort_order' })
  sortOrder: number;

  @HasMany(() => WorkoutLoadEntry)
  loads: WorkoutLoadEntry[];

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
