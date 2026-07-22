import { StoreCatalogCategory } from '../models/store-catalog-item.model';

export type StoreCatalogSeedItem = {
  itemKey: string;
  category: StoreCatalogCategory;
  name: string;
  description: string | null;
  priceGold: number;
  sortOrder: number;
};

export const DEFAULT_STORE_CATALOG_ITEMS: StoreCatalogSeedItem[] = [
  {
    itemKey: 'cat_ears_soft',
    category: 'avatar_frame',
    name: 'Orelhas de Gato',
    description: 'Moldura suave com orelhinhas felinas.',
    priceGold: 90,
    sortOrder: 40,
  },
  {
    itemKey: 'gator_tail_fin',
    category: 'avatar_frame',
    name: 'Cauda de Jacare',
    description: 'Moldura suave inspirada no estilo do Jaca.',
    priceGold: 110,
    sortOrder: 50,
  },
  {
    itemKey: 'fox_autumn_tail',
    category: 'avatar_frame',
    name: 'Raposa de Outono',
    description: 'Orelhas e cauda felpuda em tons de outono.',
    priceGold: 140,
    sortOrder: 60,
  },
  {
    itemKey: 'panda_bamboo',
    category: 'avatar_frame',
    name: 'Panda Bamboo',
    description: 'Orelhas e patinhas de panda com bambu fresco.',
    priceGold: 130,
    sortOrder: 70,
  },
  {
    itemKey: 'fire_streak',
    category: 'avatar_frame',
    name: 'Chama da Sequencia',
    description: 'Anel em brasa com chamas da ofensiva.',
    priceGold: 220,
    sortOrder: 80,
  },
  {
    itemKey: 'fruit_ring',
    category: 'avatar_frame',
    name: 'Coroa de Frutas',
    description: 'Frutas e vegetais frescos ao redor do perfil.',
    priceGold: 160,
    sortOrder: 90,
  },
  {
    itemKey: 'royal_gold',
    category: 'avatar_frame',
    name: 'Ouro Real',
    description: 'Anel dourado com coroa, gemas e moedas.',
    priceGold: 1000,
    sortOrder: 100,
  },
  {
    itemKey: 'sunset_orbit',
    category: 'avatar_background',
    name: 'Sunset Orbit',
    description: 'Por do sol com orbitas suaves.',
    priceGold: 130,
    sortOrder: 10,
  },
  {
    itemKey: 'jungle_neon',
    category: 'avatar_background',
    name: 'Jungle Neon',
    description: 'Selva vibrante com brilho neon.',
    priceGold: 190,
    sortOrder: 20,
  },
  {
    itemKey: 'aurora_grid',
    category: 'avatar_background',
    name: 'Aurora Grid',
    description: 'Aurora boreal com grade futurista.',
    priceGold: 250,
    sortOrder: 30,
  },
  {
    itemKey: 'sky',
    category: 'avatar_background',
    name: 'Sky',
    description: 'Ceú aberto com tons azuis.',
    priceGold: 150,
    sortOrder: 40,
  },
  {
    itemKey: 'pantano',
    category: 'avatar_background',
    name: 'Pantano',
    description: 'Atmosfera verde e misteriosa.',
    priceGold: 220,
    sortOrder: 50,
  },
  {
    itemKey: 'offensive_guard',
    category: 'offensive_blocker',
    name: 'Bloqueador de sequência',
    description: null,
    priceGold: 80,
    sortOrder: 10,
  },
  {
    itemKey: 'streak_restore',
    category: 'streak_restore',
    name: 'Restaurar sequências perdidas até então',
    description: null,
    priceGold: 0,
    sortOrder: 20,
  },
];

/** Keys removed from the public catalog; kept inactive for existing purchases. */
export const DEPRECATED_STORE_CATALOG_ITEM_KEYS = [
  'emerald_guard',
  'crystal_champion',
  'cosmic_blossom',
] as const;
