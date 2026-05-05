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

  @Default(2000)
  @Column({ type: DataType.DECIMAL, field: 'daily_calorie_goal' })
  dailyCalorieGoal: number;

  @Default(120)
  @Column({ type: DataType.DECIMAL, field: 'daily_protein_goal' })
  dailyProteinGoal: number;

  @Default(200)
  @Column({ type: DataType.DECIMAL, field: 'daily_carbs_goal' })
  dailyCarbsGoal: number;

  @Default(60)
  @Column({ type: DataType.DECIMAL, field: 'daily_fat_goal' })
  dailyFatGoal: number;

  @AllowNull(true)
  @Column({ type: DataType.DATEONLY, field: 'birth_date' })
  birthDate: string | null;

  @AllowNull(true)
  @Column({ type: DataType.DECIMAL, field: 'weight' })
  weight: number | null;

  @AllowNull(true)
  @Column({ type: DataType.DECIMAL, field: 'height' })
  height: number | null;

  @Default('kg')
  @Column({ type: DataType.STRING, field: 'weight_unit' })
  weightUnit: string | null;

  @Default('cm')
  @Column({ type: DataType.STRING, field: 'height_unit' })
  heightUnit: string | null;

  @AllowNull(true)
  @Column({ type: DataType.STRING, field: 'sex' })
  sex: string | null;

  @AllowNull(true)
  @Column({ type: DataType.STRING, field: 'objective' })
  objective: string | null;

  @AllowNull(true)
  @Column({ type: DataType.STRING, field: 'activity_level' })
  activityLevel: string | null;

  @AllowNull(true)
  @Column({ type: DataType.STRING, field: 'avatar_url' })
  avatarUrl: string | null;

  @Default(false)
  @Column({ type: DataType.BOOLEAN, field: 'hide_missions_guide_me' })
  hideMissionsGuideMe: boolean;

  @Default(false)
  @Column({ type: DataType.BOOLEAN, field: 'hide_social_guide_me' })
  hideSocialGuideMe: boolean;

  @AllowNull(true)
  @Column({ type: DataType.BOOLEAN, field: 'hide_guide_me' })
  hideGuideMe: boolean | null;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
