export const AVATAR_FRAME_NONE_ID = 'none';
export const AVATAR_BACKGROUND_NONE_ID = 'none';
export const OFFENSIVE_BLOCKER_DEFAULT_ID = 'offensive_guard';
export const OFFENSIVE_BLOCKER_PRICE_GOLD = 80;

export const AVATAR_FRAME_PRICES_GOLD: Record<string, number> = {
  emerald_guard: 120,
  crystal_champion: 180,
  cosmic_blossom: 260,
  cat_ears_soft: 90,
  gator_tail_fin: 110,
};

export const AVATAR_BACKGROUND_PRICES_GOLD: Record<string, number> = {
  sunset_orbit: 130,
  jungle_neon: 190,
  aurora_grid: 250,
  mango_sky: 140,
  mint_cloud: 170,
  sky: 150,
  pantano: 220,
};

export function avatarFramePriceGold(frameId: string): number | null {
  if (!frameId || frameId.trim().length === 0 || frameId === AVATAR_FRAME_NONE_ID) {
    return null;
  }

  const normalized = frameId.trim();
  if (!(normalized in AVATAR_FRAME_PRICES_GOLD)) {
    return null;
  }

  return AVATAR_FRAME_PRICES_GOLD[normalized];
}

export function avatarBackgroundPriceGold(backgroundId: string): number | null {
  if (
    !backgroundId ||
    backgroundId.trim().length === 0 ||
    backgroundId === AVATAR_BACKGROUND_NONE_ID
  ) {
    return null;
  }

  const normalized = backgroundId.trim();
  if (!(normalized in AVATAR_BACKGROUND_PRICES_GOLD)) {
    return null;
  }

  return AVATAR_BACKGROUND_PRICES_GOLD[normalized];
}
