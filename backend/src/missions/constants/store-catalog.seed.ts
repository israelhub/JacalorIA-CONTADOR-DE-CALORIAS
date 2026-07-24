import { StoreCatalogCategory } from '../models/store-catalog-item.model';

/**
 * Economia da loja (sink de ouro).
 *
 * Escada de preços vs rendimento (~40 ouro/dia engajado, ~20 casual):
 * - Entry (1–2 dias): primeira compra rápida → retenção inicial
 * - Mid (3–7 dias): progresso visível semana a semana
 * - Rare (~2 semanas): status intermediário
 * - Legendary (1–2 meses): meta aspiracional de longo prazo
 * - Bloqueador (~2,5 dias): loss aversion útil, sem ser punitivo
 *
 * Total cosméticos ativos ≈ 3835 ouro → sink maior que 1 mês perfeito.
 */
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
    priceGold: 45,
    sortOrder: 10,
  },
  {
    itemKey: 'gator_tail_fin',
    category: 'avatar_frame',
    name: 'Cauda de Jacare',
    description: 'Moldura suave inspirada no estilo do Jaca.',
    priceGold: 70,
    sortOrder: 20,
  },
  {
    itemKey: 'panda_bamboo',
    category: 'avatar_frame',
    name: 'Panda Bamboo',
    description: 'Orelhas e patinhas de panda com bambu fresco.',
    priceGold: 100,
    sortOrder: 30,
  },
  {
    itemKey: 'fox_autumn_tail',
    category: 'avatar_frame',
    name: 'Raposa de Outono',
    description: 'Orelhas e cauda felpuda em tons de outono.',
    priceGold: 150,
    sortOrder: 40,
  },
  {
    itemKey: 'fruit_ring',
    category: 'avatar_frame',
    name: 'Coroa de Frutas',
    description: 'Frutas e vegetais frescos ao redor do perfil.',
    priceGold: 200,
    sortOrder: 50,
  },
  {
    itemKey: 'fire_streak',
    category: 'avatar_frame',
    name: 'Chama da Sequencia',
    description: 'Anel em brasa com chamas da ofensiva.',
    priceGold: 350,
    sortOrder: 60,
  },
  {
    itemKey: 'royal_gold',
    category: 'avatar_frame',
    name: 'Ouro Real',
    description: 'Anel dourado com coroa, gemas e moedas.',
    priceGold: 2000,
    sortOrder: 70,
  },
  {
    itemKey: 'soft_pink',
    category: 'avatar_frame',
    name: 'Rosa Suave',
    description: 'Anel rosa simples com brilhos e coracoes.',
    priceGold: 40,
    sortOrder: 5,
  },
  {
    itemKey: 'soft_blue',
    category: 'avatar_frame',
    name: 'Azul Suave',
    description: 'Anel azul simples com brilhos e bolhas.',
    priceGold: 40,
    sortOrder: 6,
  },
  {
    itemKey: 'sky',
    category: 'avatar_background',
    name: 'Sky',
    description: 'Ceú aberto com tons azuis.',
    priceGold: 55,
    sortOrder: 10,
  },
  {
    itemKey: 'sunset_orbit',
    category: 'avatar_background',
    name: 'Sunset Orbit',
    description: 'Por do sol com orbitas suaves.',
    priceGold: 85,
    sortOrder: 20,
  },
  {
    itemKey: 'jungle_neon',
    category: 'avatar_background',
    name: 'Jungle Neon',
    description: 'Selva vibrante com brilho neon.',
    priceGold: 160,
    sortOrder: 30,
  },
  {
    itemKey: 'pantano',
    category: 'avatar_background',
    name: 'Pantano',
    description: 'Atmosfera verde e misteriosa.',
    priceGold: 220,
    sortOrder: 40,
  },
  {
    itemKey: 'aurora_grid',
    category: 'avatar_background',
    name: 'Aurora Grid',
    description: 'Aurora boreal com grade futurista.',
    priceGold: 400,
    sortOrder: 50,
  },
  {
    itemKey: 'bamboo_grove',
    category: 'avatar_background',
    name: 'Bosque de Bambu',
    description: 'Bambuzal sereno para combinar com o Panda.',
    priceGold: 120,
    sortOrder: 60,
  },
  {
    itemKey: 'autumn_woods',
    category: 'avatar_background',
    name: 'Floresta de Outono',
    description: 'Folhas douradas para acompanhar a Raposa de Outono.',
    priceGold: 180,
    sortOrder: 70,
  },
  {
    itemKey: 'orchard_fresh',
    category: 'avatar_background',
    name: 'Pomar Fresco',
    description: 'Frutas frescas que combinam com a Coroa de Frutas.',
    priceGold: 240,
    sortOrder: 80,
  },
  {
    itemKey: 'ember_blaze',
    category: 'avatar_background',
    name: 'Brasas em Chamas',
    description: 'Fogo intenso para combinar com a Chama da Sequencia.',
    priceGold: 380,
    sortOrder: 90,
  },
  {
    itemKey: 'royal_court',
    category: 'avatar_background',
    name: 'Corte Real',
    description: 'Ouro e joias para combinar com o Ouro Real.',
    priceGold: 1500,
    sortOrder: 100,
  },
  {
    itemKey: 'soft_pink',
    category: 'avatar_background',
    name: 'Rosa Suave',
    description: 'Tons rosa para combinar com a moldura Rosa Suave.',
    priceGold: 50,
    sortOrder: 5,
  },
  {
    itemKey: 'soft_blue',
    category: 'avatar_background',
    name: 'Azul Suave',
    description: 'Tons azuis para combinar com a moldura Azul Suave.',
    priceGold: 50,
    sortOrder: 6,
  },
  {
    itemKey: 'offensive_guard',
    category: 'offensive_blocker',
    name: 'Bloqueador de sequência',
    description: 'Protege sua ofensiva por 1 dia perdido.',
    priceGold: 100,
    sortOrder: 10,
  },
];

/** Keys removed from the public catalog; kept inactive for existing purchases. */
export const DEPRECATED_STORE_CATALOG_ITEM_KEYS = [
  'emerald_guard',
  'crystal_champion',
  'cosmic_blossom',
  'streak_restore',
] as const;
