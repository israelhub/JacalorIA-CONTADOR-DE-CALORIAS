import {
  AllowNull,
  Column,
  CreatedAt,
  DataType,
  Default,
  Model,
  PrimaryKey,
  Table,
  Unique,
  UpdatedAt,
} from 'sequelize-typescript';

export type StoreCatalogCategory =
  | 'avatar_frame'
  | 'avatar_background'
  | 'offensive_blocker'
  | 'streak_restore';

@Table({
  tableName: 'store_catalog_items',
  underscored: true,
  indexes: [
    {
      name: 'idx_store_catalog_items_category_active',
      fields: ['category', 'is_active', 'sort_order'],
    },
  ],
})
export class StoreCatalogItem extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id: string;

  @Unique
  @AllowNull(false)
  @Column({ type: DataType.STRING, field: 'item_key' })
  itemKey: string;

  @AllowNull(false)
  @Column(DataType.STRING)
  category: StoreCatalogCategory;

  @AllowNull(false)
  @Column(DataType.STRING)
  name: string;

  @AllowNull(true)
  @Column(DataType.STRING)
  description: string | null;

  @AllowNull(false)
  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'price_gold' })
  priceGold: number;

  @AllowNull(false)
  @Default(0)
  @Column({ type: DataType.INTEGER, field: 'sort_order' })
  sortOrder: number;

  @AllowNull(false)
  @Default(true)
  @Column({ type: DataType.BOOLEAN, field: 'is_active' })
  isActive: boolean;

  @CreatedAt
  @Column({ field: 'created_at' })
  createdAt: Date;

  @UpdatedAt
  @Column({ field: 'updated_at' })
  updatedAt: Date;
}
