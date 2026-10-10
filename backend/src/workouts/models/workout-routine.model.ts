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
import { WorkoutExercise } from './workout-exercise.model';

@Table({ tableName: 'workout_routines', underscored: true })
export class WorkoutRoutine extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string;

  @BelongsTo(() => User)
  user: User;

  @AllowNull(false)
  @Column(DataType.STRING)
  name: string;

  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'sort_order' })
  sortOrder: number;

  @HasMany(() => WorkoutExercise)
  exercises: WorkoutExercise[];

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
