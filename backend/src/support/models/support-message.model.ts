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
import type { SupportSubjectType } from '../dto/create-support-message.dto';

@Table({
  tableName: 'support_messages',
  underscored: true,
  updatedAt: false,
})
export class SupportMessage extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @ForeignKey(() => User)
  @AllowNull(true)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string | null;

  @BelongsTo(() => User, { onDelete: 'SET NULL' })
  user: User | null;

  @AllowNull(false)
  @Column({ type: DataType.STRING(32), field: 'subject_type' })
  subjectType: SupportSubjectType;

  @AllowNull(false)
  @Column(DataType.TEXT)
  description: string;

  @AllowNull(true)
  @Column({ type: DataType.STRING(255), field: 'contact_email' })
  contactEmail: string | null;

  @AllowNull(true)
  @Column({ type: DataType.STRING(255), field: 'user_email' })
  userEmail: string | null;

  @AllowNull(true)
  @Column({ type: DataType.STRING(255), field: 'user_name' })
  userName: string | null;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;
}
