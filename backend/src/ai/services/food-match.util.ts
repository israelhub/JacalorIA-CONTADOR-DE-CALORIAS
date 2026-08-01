export type MatchableFood = {
  description: string;
  normalizedDescription: string;
  tokens: string[];
  tokenSet: Set<string>;
  category: string | null;
};

export type FoodMatchResult<T extends MatchableFood = MatchableFood> = {
  score: number;
  food: T;
  foodCoverage: number;
  prepPreference: number;
  cutPreference: number;
};

const STOP_WORDS = new Set([
  'de',
  'da',
  'do',
  'das',
  'dos',
  'com',
  'sem',
  'ao',
  'aos',
  'na',
  'no',
  'nas',
  'nos',
  'e',
  'ou',
  'em',
  'a',
  'o',
]);

/** Preparos que distorcem muito as kcal — só penalizam se a query NÃO os mencionar. */
const HIGH_IMPACT_MODIFIERS = new Set([
  'doce',
  'calda',
  'drenado',
  'frito',
  'frita',
  'empanado',
  'empanada',
  'milanesa',
  'xarope',
  'cristalizado',
  'cristalizada',
  'conserva',
  'refogado',
  'refogada',
  'ensopado',
  'ensopada',
]);

const RAW_TOKENS = new Set(['cru', 'crua']);

const COOKED_PREFERENCE: Record<string, number> = {
  grelhado: 3,
  grelhada: 3,
  assado: 2,
  assada: 2,
  cozido: 1,
  cozida: 1,
};

/** Cortes comuns quando a query não cita corte (ex.: só "frango"). */
const DEFAULT_CUT_PREFERENCE: Record<string, number> = {
  peito: 4,
  file: 3,
  coxa: 1,
};

const UNCOMMON_CUT_PENALTY: Record<string, number> = {
  coracao: -0.2,
  figado: -0.2,
  asa: -0.15,
  sobrecoxa: -0.08,
  inteiro: -0.08,
};

const CUT_QUERY_TOKENS = new Set([
  ...Object.keys(DEFAULT_CUT_PREFERENCE),
  ...Object.keys(UNCOMMON_CUT_PENALTY),
]);

const PREP_QUERY_TOKENS = new Set([
  ...HIGH_IMPACT_MODIFIERS,
  ...RAW_TOKENS,
  ...Object.keys(COOKED_PREFERENCE),
]);

const MEAT_CATEGORIES = new Set([
  'carnes e derivados',
  'pescados e frutos do mar',
  'ovos e derivados',
]);

/** Cortes (peito/asa) só fazem sentido em carnes/pescados — não em ovos. */
const MEAT_CUT_CATEGORIES = new Set([
  'carnes e derivados',
  'pescados e frutos do mar',
]);

const LEGUME_CATEGORIES = new Set(['leguminosas e derivados']);

const EGG_CATEGORIES = new Set(['ovos e derivados']);

/** Variedades comuns de feijão quando a query é só "feijão". */
const COMMON_BEAN_VARIETIES: Record<string, number> = {
  carioca: 3,
  preto: 2,
};

export function normalizeFoodName(value: string): string {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function tokenizeFoodName(normalized: string): string[] {
  const baseTokens = normalized.split(' ').filter((token) => token.length > 1);
  const filtered = baseTokens.filter((token) => !STOP_WORDS.has(token));
  return filtered.length ? filtered : baseTokens;
}

export function buildMatchableFood(input: {
  description: string;
  category?: string | null;
}): MatchableFood {
  const description = input.description.trim();
  const normalizedDescription = normalizeFoodName(description);
  const tokens = tokenizeFoodName(normalizedDescription);
  return {
    description,
    normalizedDescription,
    tokens,
    tokenSet: new Set(tokens),
    category: input.category ?? null,
  };
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/** Match de frase só em limites de palavra (evita agua ⊂ aguardente). */
export function hasWordBoundaryMatch(
  haystackNormalized: string,
  needleNormalized: string,
): boolean {
  if (!haystackNormalized || !needleNormalized) {
    return false;
  }
  if (haystackNormalized === needleNormalized) {
    return true;
  }
  const pattern = new RegExp(
    `(?:^|\\s)${escapeRegExp(needleNormalized)}(?:\\s|$)`,
  );
  return pattern.test(haystackNormalized);
}

function normalizeCategory(category: string | null): string {
  return normalizeFoodName(category ?? '');
}

function isMeatCategory(category: string | null): boolean {
  return MEAT_CATEGORIES.has(normalizeCategory(category));
}

function isMeatCutCategory(category: string | null): boolean {
  return MEAT_CUT_CATEGORIES.has(normalizeCategory(category));
}

function isLegumeCategory(category: string | null): boolean {
  return LEGUME_CATEGORIES.has(normalizeCategory(category));
}

function isEggCategory(category: string | null): boolean {
  return EGG_CATEGORIES.has(normalizeCategory(category));
}

function queryWantsCooked(queryTokens: string[]): boolean {
  return queryTokens.includes('cozido') || queryTokens.includes('cozida');
}

function queryWantsRaw(queryTokens: string[]): boolean {
  return queryTokens.some((token) => RAW_TOKENS.has(token));
}

function foodIsRaw(food: MatchableFood): boolean {
  return food.tokens.some((token) => RAW_TOKENS.has(token));
}

function foodIsCookedLegume(food: MatchableFood): boolean {
  return food.tokens.includes('cozido') || food.tokens.includes('cozida');
}

/**
 * Query pede cozido mas o match TACO é cru (ou o inverso).
 * Ex.: "grão de bico cozido" vs "Grão-de-bico, cru" — não forçar o cru.
 */
export function hasCookedRawConflict(
  foodName: string,
  food: MatchableFood,
): boolean {
  const tokens = tokenizeFoodName(normalizeFoodName(foodName));
  if (queryWantsCooked(tokens) && foodIsRaw(food)) {
    return true;
  }
  if (queryWantsRaw(tokens) && foodIsCookedLegume(food)) {
    return true;
  }
  return false;
}

function isPrepOrStateToken(token: string): boolean {
  return (
    PREP_QUERY_TOKENS.has(token) ||
    token === 'cozido' ||
    token === 'cozida' ||
    RAW_TOKENS.has(token)
  );
}

function contentTokens(tokens: string[]): string[] {
  return tokens.filter((token) => !isPrepOrStateToken(token));
}

function queryMentionsPrep(queryTokens: string[]): boolean {
  return queryTokens.some((token) => PREP_QUERY_TOKENS.has(token));
}

function queryMentionsCut(queryTokens: string[]): boolean {
  return queryTokens.some((token) => CUT_QUERY_TOKENS.has(token));
}

function countSharedTokens(tokens: string[], food: MatchableFood): number {
  let shared = 0;
  for (const token of tokens) {
    if (food.tokenSet.has(token)) {
      shared += 1;
    }
  }
  return shared;
}

export function isPotentialFoodCandidate(
  normalizedQuery: string,
  queryTokens: string[],
  food: MatchableFood,
): boolean {
  if (
    hasWordBoundaryMatch(food.normalizedDescription, normalizedQuery) ||
    hasWordBoundaryMatch(normalizedQuery, food.normalizedDescription)
  ) {
    return true;
  }

  // Não candidatar só por "cozido"/"cru" — precisa overlap do alimento em si.
  const queryContent = contentTokens(queryTokens);
  if (queryContent.length > 0) {
    return queryContent.some((token) => food.tokenSet.has(token));
  }

  for (const token of queryTokens) {
    if (food.tokenSet.has(token)) {
      return true;
    }
  }

  return false;
}

function highImpactPenalty(queryTokens: string[], food: MatchableFood): number {
  const querySet = new Set(queryTokens);
  let penalty = 0;
  for (const token of food.tokens) {
    if (HIGH_IMPACT_MODIFIERS.has(token) && !querySet.has(token)) {
      penalty += 0.18;
    }
  }
  return penalty;
}

function categoryPrepAdjustment(
  queryTokens: string[],
  food: MatchableFood,
): { scoreDelta: number; prepPreference: number } {
  if (isLegumeCategory(food.category)) {
    const wantsCooked = queryWantsCooked(queryTokens);
    const wantsRaw = queryWantsRaw(queryTokens);

    let scoreDelta = 0;
    let prepPreference = 0;
    for (const token of food.tokens) {
      if (RAW_TOKENS.has(token)) {
        if (wantsCooked) {
          // Nunca empurrar "cozido" para o grão seco da TACO.
          scoreDelta -= 0.55;
          prepPreference -= 6;
        } else if (!wantsRaw) {
          scoreDelta -= 0.28;
          prepPreference -= 3;
        } else {
          scoreDelta += 0.15;
          prepPreference += 2;
        }
      }
      if (token === 'cozido' || token === 'cozida') {
        if (wantsRaw) {
          scoreDelta -= 0.55;
          prepPreference -= 6;
        } else {
          scoreDelta += 0.2;
          prepPreference += 3;
        }
      }
      const beanRank = COMMON_BEAN_VARIETIES[token];
      if (beanRank) {
        scoreDelta += 0.04 * beanRank;
        prepPreference += beanRank;
      }
    }
    return { scoreDelta, prepPreference };
  }

  if (!isMeatCategory(food.category) || queryMentionsPrep(queryTokens)) {
    return { scoreDelta: 0, prepPreference: 0 };
  }

  let scoreDelta = 0;
  let prepPreference = 0;

  for (const token of food.tokens) {
    if (RAW_TOKENS.has(token)) {
      scoreDelta -= 0.22;
      prepPreference -= 2;
    }
    const cookedRank = COOKED_PREFERENCE[token];
    if (cookedRank) {
      scoreDelta += 0.06 * cookedRank;
      prepPreference = Math.max(prepPreference, cookedRank);
    }
    if (HIGH_IMPACT_MODIFIERS.has(token)) {
      prepPreference -= 1;
    }
  }

  return { scoreDelta, prepPreference };
}

/**
 * Preferência de corte quando a query não especifica.
 * Carnes: peito > filé. Ovos: inteiro (não só gema/clara).
 */
function categoryCutAdjustment(
  queryTokens: string[],
  food: MatchableFood,
): { scoreDelta: number; cutPreference: number } {
  if (isEggCategory(food.category)) {
    if (queryTokens.includes('gema') || queryTokens.includes('clara')) {
      return { scoreDelta: 0, cutPreference: 0 };
    }

    let scoreDelta = 0;
    let cutPreference = 0;
    for (const token of food.tokens) {
      if (token === 'inteiro') {
        scoreDelta += 0.12;
        cutPreference = Math.max(cutPreference, 3);
      }
      if (token === 'gema' || token === 'clara') {
        scoreDelta -= 0.15;
        cutPreference -= 2;
      }
    }
    return { scoreDelta, cutPreference };
  }

  if (!isMeatCutCategory(food.category) || queryMentionsCut(queryTokens)) {
    return { scoreDelta: 0, cutPreference: 0 };
  }

  let scoreDelta = 0;
  let cutPreference = 0;

  for (const token of food.tokens) {
    const preferred = DEFAULT_CUT_PREFERENCE[token];
    if (preferred) {
      scoreDelta += 0.05 * preferred;
      cutPreference = Math.max(cutPreference, preferred);
    }
    const uncommon = UNCOMMON_CUT_PENALTY[token];
    if (uncommon) {
      scoreDelta += uncommon;
      cutPreference += uncommon * 10;
    }
  }

  return { scoreDelta, cutPreference };
}

export function scoreFoodMatch(
  normalizedQuery: string,
  queryTokens: string[],
  food: MatchableFood,
): {
  score: number;
  foodCoverage: number;
  prepPreference: number;
  cutPreference: number;
} {
  if (normalizedQuery === food.normalizedDescription) {
    return { score: 1, foodCoverage: 1, prepPreference: 0, cutPreference: 0 };
  }

  const shared = countSharedTokens(queryTokens, food);
  const tokenOverlap = queryTokens.length ? shared / queryTokens.length : 0;
  const foodCoverage = food.tokens.length ? shared / food.tokens.length : 0;
  const hasPhraseMatch =
    hasWordBoundaryMatch(food.normalizedDescription, normalizedQuery) ||
    hasWordBoundaryMatch(normalizedQuery, food.normalizedDescription);
  const sameFirstToken =
    queryTokens.length > 0 &&
    food.tokens.length > 0 &&
    queryTokens[0] === food.tokens[0];

  const shortQueryExtraPenalty =
    queryTokens.length <= 2
      ? Math.max(0, food.tokens.length - shared) * 0.05
      : 0;

  const prep = categoryPrepAdjustment(queryTokens, food);
  const cut = categoryCutAdjustment(queryTokens, food);

  // "grao de bico" vs "feijao ... cozido": só "cozido" em comum não basta.
  const queryContent = contentTokens(queryTokens);
  if (queryContent.length > 0) {
    const sharedContent = queryContent.filter((token) =>
      food.tokenSet.has(token),
    ).length;
    if (sharedContent === 0) {
      return {
        score: 0,
        foodCoverage,
        prepPreference: prep.prepPreference,
        cutPreference: cut.cutPreference,
      };
    }
  }

  const rawScore =
    tokenOverlap * 0.45 +
    foodCoverage * 0.35 +
    (hasPhraseMatch ? 0.12 : 0) +
    (sameFirstToken ? 0.1 : 0) +
    (queryTokens.length === 1 && shared === 1 ? 0.05 : 0) +
    prep.scoreDelta +
    cut.scoreDelta -
    highImpactPenalty(queryTokens, food) -
    shortQueryExtraPenalty;

  const score = Math.max(0, Math.min(1, rawScore));
  return {
    score,
    foodCoverage,
    prepPreference: prep.prepPreference,
    cutPreference: cut.cutPreference,
  };
}

function isBetterMatch<T extends MatchableFood>(
  candidate: FoodMatchResult<T>,
  currentBest: FoodMatchResult<T>,
): boolean {
  if (candidate.score !== currentBest.score) {
    return candidate.score > currentBest.score;
  }
  if (candidate.cutPreference !== currentBest.cutPreference) {
    return candidate.cutPreference > currentBest.cutPreference;
  }
  if (candidate.prepPreference !== currentBest.prepPreference) {
    return candidate.prepPreference > currentBest.prepPreference;
  }
  if (candidate.foodCoverage !== currentBest.foodCoverage) {
    return candidate.foodCoverage > currentBest.foodCoverage;
  }
  return (
    candidate.food.normalizedDescription.length <
    currentBest.food.normalizedDescription.length
  );
}

export function findBestFoodMatch<T extends MatchableFood>(
  foodName: string,
  foods: T[],
  threshold: number,
): FoodMatchResult<T> | null {
  const normalized = normalizeFoodName(foodName);
  if (!normalized) {
    return null;
  }

  const tokens = tokenizeFoodName(normalized);
  let best: FoodMatchResult<T> | null = null;

  for (const food of foods) {
    if (!isPotentialFoodCandidate(normalized, tokens, food)) {
      continue;
    }

    const scored = scoreFoodMatch(normalized, tokens, food);
    const candidate: FoodMatchResult<T> = {
      score: scored.score,
      food,
      foodCoverage: scored.foodCoverage,
      prepPreference: scored.prepPreference,
      cutPreference: scored.cutPreference,
    };

    if (!best || isBetterMatch(candidate, best)) {
      best = candidate;
    }
  }

  if (!best || best.score < threshold) {
    return null;
  }

  if (hasCookedRawConflict(foodName, best.food)) {
    return null;
  }

  return best;
}
