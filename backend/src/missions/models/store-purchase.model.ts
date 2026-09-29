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
import { StoreCatalogCategory } from './store-catalog-item.model';

export type StorePurchaseAcquireSource = 'purchase' | 'check_in' | 'migration';

@Table({
  tableName: 'store_purchases',
  underscored: true,
  indexes: [
    {
      name: 'idx_store_purchases_user_item',
      fields: ['user_id', 'item_key'],
    },
    {
      name: 'idx_store_purchases_user_category',
      fields: ['user_id', 'category'],
    },
  ],
})
export class StorePurchase extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @AllowNull(false)
  @Column({ type: DataType.UUID, field: 'user_id' })
  userId: string;

  @AllowNull(true)
  @Column({ type: DataType.UUID, field: 'catalog_item_id' })
  catalogItemId: string | null;

  @AllowNull(false)
  @Column({ type: DataType.STRING, field: 'item_key' })
  itemKey: string;

  @AllowNull(false)
  @Column(DataType.STRING)
  category: StoreCatalogCategory | string;

  @AllowNull(false)
  @Default(1)
  @Column(DataType.INTEGER)
  quantity: number;

  @AllowNull(false)
  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'price_gold' })
  priceGold: number;

  @AllowNull(true)
  @Column({ type: DataType.UUID, field: 'currency_transaction_id' })
  currencyTransactionId: string | null;

  @AllowNull(false)
  @Default('purchase')
  @Column({ type: DataType.STRING, field: 'acquire_source' })
  acquireSource: StorePurchaseAcquireSource;

  @AllowNull(true)
  @Column({ type: DataType.STRING, field: 'reference_key' })
  referenceKey: string | null;

  @AllowNull(false)
  @Default(DataType.NOW)
  @Column({ type: DataType.DATE, field: 'purchased_at' })
  purchasedAt: Date;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
