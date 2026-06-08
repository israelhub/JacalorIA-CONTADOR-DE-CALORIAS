import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { DEFAULT_STORE_CATALOG_ITEMS } from './constants/store-catalog.seed';
import {
  StoreCatalogCategory,
  StoreCatalogItem,
} from './models/store-catalog-item.model';

@Injectable()
export class StoreCatalogService implements OnModuleInit {
  constructor(
    @InjectModel(StoreCatalogItem)
    private readonly storeCatalogItemModel: typeof StoreCatalogItem,
  ) {}

  async onModuleInit() {
    await this.ensureSeeded();
  }

  async ensureSeeded(): Promise<void> {
    const count = await this.storeCatalogItemModel.count();
    if (count > 0) {
      return;
    }

    await this.storeCatalogItemModel.bulkCreate(
      DEFAULT_STORE_CATALOG_ITEMS.map((item) => ({
        itemKey: item.itemKey,
        category: item.category,
        name: item.name,
        description: item.description,
        priceGold: item.priceGold,
        sortOrder: item.sortOrder,
        isActive: true,
      })),
    );
  }

  async listActiveByCategory(
    category: StoreCatalogCategory,
  ): Promise<StoreCatalogItem[]> {
    await this.ensureSeeded();

    return this.storeCatalogItemModel.findAll({
      where: { category, isActive: true },
      order: [
        ['sortOrder', 'ASC'],
        ['itemKey', 'ASC'],
      ],
    });
  }

  async findActiveByKey(itemKey: string): Promise<StoreCatalogItem | null> {
    await this.ensureSeeded();

    const normalized = itemKey.trim();
    if (!normalized) {
      return null;
    }

    return this.storeCatalogItemModel.findOne({
      where: { itemKey: normalized, isActive: true },
    });
  }

  async getActivePriceGold(itemKey: string): Promise<number | null> {
    const item = await this.findActiveByKey(itemKey);
    return item?.priceGold ?? null;
  }

  async listActiveBackgroundKeys(): Promise<string[]> {
    const items = await this.listActiveByCategory('avatar_background');
    return items.map((item) => item.itemKey);
  }
}
