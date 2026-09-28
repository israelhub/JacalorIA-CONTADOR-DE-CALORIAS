/**
 * Helpers puros do vínculo usuário↔missão / referência de compra.
 * Mantidos sem I/O para testes unitários.
 */

export type MissionRewardReferenceParts = {
  missionKey: string;
  periodKey: string;
};

export function buildMissionRewardReferenceKey(
  missionKey: string,
  periodKey: string,
): string {
  return `mission_reward:${missionKey}:${periodKey}`;
}

export function parseMissionRewardReferenceKey(
  referenceKey: string | null | undefined,
): MissionRewardReferenceParts | null {
  const raw = referenceKey?.trim() ?? '';
  if (!raw.startsWith('mission_reward:')) {
    return null;
  }

  const parts = raw.split(':');
  if (parts.length < 3) {
    return null;
  }

  const missionKey = parts[1]?.trim() ?? '';
  const periodKey = parts.slice(2).join(':').trim();
  if (!missionKey || !periodKey) {
    return null;
  }

  return { missionKey, periodKey };
}

export function resolveUserMissionStatus(params: {
  progressCurrent: number;
  progressTarget: number;
  alreadyCompleted?: boolean;
}): 'in_progress' | 'completed' {
  if (params.alreadyCompleted) {
    return 'completed';
  }

  const target = Math.max(1, params.progressTarget);
  const current = Math.max(0, params.progressCurrent);
  return current >= target ? 'completed' : 'in_progress';
}

export function buildStorePurchaseReferenceKey(params: {
  sourceType: string;
  itemKey: string;
  suffix?: string;
}): string {
  const itemKey = params.itemKey.trim();
  if (params.suffix) {
    return `${params.sourceType}:${itemKey}:${params.suffix}`;
  }
  return `${params.sourceType}:${itemKey}`;
}

export function mergeOwnedItemKeys(
  primary: Iterable<string>,
  fallback: Iterable<string>,
): string[] {
  const owned = new Set<string>();
  for (const value of primary) {
    const normalized = value?.toString().trim() ?? '';
    if (normalized) {
      owned.add(normalized);
    }
  }
  for (const value of fallback) {
    const normalized = value?.toString().trim() ?? '';
    if (normalized) {
      owned.add(normalized);
    }
  }
  return Array.from(owned).sort();
}
