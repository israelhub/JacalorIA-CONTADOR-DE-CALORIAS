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
    itemKey: 'emerald_guard',
    category: 'avatar_frame',
    name: 'Guarda Esmeralda',
    description: 'Folhas de armadura, ouro e cristais verdes.',
    priceGold: 120,
    sortOrder: 10,
  },
  {
    itemKey: 'crystal_champion',
    category: 'avatar_frame',
    name: 'Campeao Cristalino',
    description: 'Cristais violetas com laterais douradas.',
    priceGold: 180,
    sortOrder: 20,
  },
  {
    itemKey: 'cosmic_blossom',
    category: 'avatar_frame',
    name: 'Floracao Cosmica',
    description: 'Galhos magenta, estrelas e joias lunares.',
    priceGold: 260,
    sortOrder: 30,
  },
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
    name: 'Bloqueador de ofensiva',
    description: 'Protege sua sequencia quando voce falha um dia.',
    priceGold: 80,
    sortOrder: 10,
  },
];
