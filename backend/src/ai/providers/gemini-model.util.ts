/** Timeout/cooldown/thinking helpers for the Gemini food-analysis chain. */

export const TOTAL_TIMEOUT_MS = 55_000;
export const PRIMARY_MODEL_TIMEOUT_MS = 25_000;
export const PER_MODEL_TIMEOUT_MS = 16_000;
/** Um pouco acima da janela de RPM do AI Studio (1 min). */
export const MODEL_COOLDOWN_MS = 65_000;
export const MAX_MODELS = 8;
/** Um pedido não pode queimar a cota RPM de toda a cadeia. */
export const MAX_ATTEMPTS_PER_REQUEST = 3;
export const DEFAULT_PRIMARY_MODEL = 'gemini-3.5-flash-lite';
export const DEFAULT_FALLBACK_MODELS = [
  'gemini-3.1-flash-lite',
  'gemini-2.5-flash-lite',
  'gemini-3.5-flash',
  'gemini-3.6-flash',
  'gemini-2.5-flash',
].join(',');

export function parseGeminiModelList(value: string): string[] {
  const models: string[] = [];
  const seen = new Set<string>();

  for (const part of value.split(',')) {
    const model = part.trim();
    if (!model || seen.has(model)) {
      continue;
    }

    seen.add(model);
    models.push(model);
    if (models.length >= MAX_MODELS) {
      break;
    }
  }

  return models.length > 0 ? models : [DEFAULT_PRIMARY_MODEL];
}

export function resolveModelTimeoutMs(
  index: number,
  remainingMs: number,
): number {
  const budget = index === 0 ? PRIMARY_MODEL_TIMEOUT_MS : PER_MODEL_TIMEOUT_MS;
  return Math.max(0, Math.min(remainingMs, budget));
}

/**
 * Cooldown only for quota/availability — a local abort does not mean the
 * model is exhausted, and skipping it on the next user tap causes 503s.
 */
export function shouldCooldownModel(errorMessage: string): boolean {
  const normalized = errorMessage.toLowerCase();
  if (normalized.includes('timeout')) {
    return false;
  }

  return (
    normalized.includes('429') ||
    normalized.includes('rate') ||
    normalized.includes('quota') ||
    normalized.includes('resource_exhausted') ||
    normalized.includes('resource exhausted') ||
    normalized.includes('unavailable')
  );
}

/**
 * Flash 3.x/2.5 think by default and can exceed our UX budget. Food JSON
 * does not need that — keep thinking off/minimal. Lite models already skip it.
 */
export function thinkingConfigForModel(
  model: string,
): Record<string, unknown> | undefined {
  const normalized = model.toLowerCase();
  const isLite = normalized.includes('lite');

  if (normalized.includes('2.5') && !isLite) {
    return { thinkingBudget: 0 };
  }

  if (
    !isLite &&
    (normalized.includes('3.5-flash') ||
      normalized.includes('3.6-flash') ||
      normalized.includes('3-flash'))
  ) {
    return { thinkingLevel: 'minimal' };
  }

  return undefined;
}
