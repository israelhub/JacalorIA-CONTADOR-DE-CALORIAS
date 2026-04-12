import {
  Table,
  Column,
  Model,
  DataType,
  CreatedAt,
  UpdatedAt,
  Default,
  PrimaryKey,
  Unique,
  AllowNull,
} from 'sequelize-typescript';

@Table({ tableName: 'users', underscored: true })
export class User extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @AllowNull(true)
  @Column(DataType.STRING)
  name: string | null;

  @Unique
  @AllowNull(false)
  @Column(DataType.STRING)
  email: string;

  @AllowNull(false)
  @Column({ type: DataType.STRING, field: 'password_hash' })
  passwordHash: string;

  @Default(false)
  @Column({ type: DataType.BOOLEAN, field: 'email_verified' })
  emailVerified: boolean;

  @AllowNull(true)
  @Column({ type: DataType.STRING(6), field: 'verification_code' })
  verificationCode: string | null;

  @AllowNull(true)
  @Column({ type: DataType.DATE, field: 'verification_code_expires_at' })
  verificationCodeExpiresAt: Date | null;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
