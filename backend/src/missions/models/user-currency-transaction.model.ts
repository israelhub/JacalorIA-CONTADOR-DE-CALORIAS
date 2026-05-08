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

export type CurrencyCode = 'gold' | 'xp';
export type CurrencyTransactionType = 'credit' | 'debit';
export type CurrencyTransactionSource =
  | 'mission_reward'
  | 'avatar_frame_purchase'
  | 'avatar_background_purchase'
  | 'offensive_blocker_purchase'
  | 'offensive_blocker_auto_purchase'
  | 'manual_adjustment';

@Table({
  tableName: 'user_currency_transactions',
  underscored: true,
  indexes: [
    {
      name: 'idx_user_currency_transactions_user_id',
      fields: ['user_id'],
    },
    {
      name: 'uniq_user_currency_reference',
      unique: true,
      fields: ['user_id', 'currency', 'reference_key'],
    },
  ],
})
export class UserCurrencyTransaction extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string;

  @AllowNull(false)
  @Column(DataType.STRING)
  currency: CurrencyCode;

  @AllowNull(false)
  @Column({ type: DataType.INTEGER, field: 'amount_signed' })
  amountSigned: number;

  @AllowNull(false)
  @Column(DataType.STRING)
  type: CurrencyTransactionType;

  @AllowNull(false)
  @Column({ type: DataType.STRING, field: 'source_type' })
  sourceType: CurrencyTransactionSource;

  @AllowNull(true)
  @Column({ type: DataType.STRING, field: 'source_id' })
  sourceId: string | null;

  @AllowNull(true)
  @Column({ type: DataType.STRING, field: 'reference_key' })
  referenceKey: string | null;

  @AllowNull(true)
  @Column(DataType.JSONB)
  metadata: Record<string, unknown> | null;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
