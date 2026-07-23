import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectModel } from '@nestjs/sequelize';
import { DEFAULT_STORE_CATALOG_ITEMS, DEPRECATED_STORE_CATALOG_ITEM_KEYS } from './constants/store-catalog.seed';
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
    for (const seed of DEFAULT_STORE_CATALOG_ITEMS) {
      const existing = await this.storeCatalogItemModel.findOne({
        where: { itemKey: seed.itemKey },
      });

      if (existing) {
        await existing.update({
          category: seed.category,
          name: seed.name,
          description: seed.description,
          priceGold: seed.priceGold,
          sortOrder: seed.sortOrder,
          isActive: true,
        });
        continue;
      }

      await this.storeCatalogItemModel.create({
        itemKey: seed.itemKey,
        category: seed.category,
        name: seed.name,
        description: seed.description,
        priceGold: seed.priceGold,
        sortOrder: seed.sortOrder,
        isActive: true,
      });
    }

    if (DEPRECATED_STORE_CATALOG_ITEM_KEYS.length > 0) {
      await this.storeCatalogItemModel.update(
        { isActive: false },
        {
          where: {
            itemKey: [...DEPRECATED_STORE_CATALOG_ITEM_KEYS],
            isActive: true,
          },
        },
      );
    }
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

  async listActiveFrameKeys(): Promise<string[]> {
    const items = await this.listActiveByCategory('avatar_frame');
    return items.map((item) => item.itemKey);
  }
}
