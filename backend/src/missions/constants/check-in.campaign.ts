import { OFFENSIVE_BLOCKER_DEFAULT_ID } from './avatar-frame-store';

export type CheckInReward =
  | { kind: 'gold'; amount: number }
  | { kind: 'blocker'; itemKey: string; quantity: number }
  | { kind: 'frame'; itemKey: string }
  | { kind: 'background'; itemKey: string };

export type CheckInDayDefinition = {
  dayKey: string;
  dayIndex: number;
  rewards: CheckInReward[];
};

export type CheckInCampaignDefinition = {
  id: string;
  title: string;
  subtitle: string;
  startDayKey: string;
  endDayKey: string;
  days: CheckInDayDefinition[];
};

const CAMPAIGN_ID = 'aug2026';

function day(
  dayKey: string,
  dayIndex: number,
  rewards: CheckInReward[],
): CheckInDayDefinition {
  return { dayKey, dayIndex, rewards };
}

/**
 * Campanha de check-in diário até o fim de agosto/2026.
 * Recompensas misturam ouro, bloqueador, moldura e fundo.
 */
export const AUGUST_2026_CHECK_IN_CAMPAIGN: CheckInCampaignDefinition = {
  id: CAMPAIGN_ID,
  title: 'Recompensas de agosto',
  subtitle: 'Ganhe recompensas até o fim de agosto',
  startDayKey: '2026-08-15',
  endDayKey: '2026-08-31',
  days: [
    day('2026-08-15', 1, [{ kind: 'gold', amount: 15 }]),
    day('2026-08-16', 2, [{ kind: 'gold', amount: 20 }]),
    day('2026-08-17', 3, [{ kind: 'gold', amount: 25 }]),
    day('2026-08-18', 4, [
      { kind: 'gold', amount: 10 },
      { kind: 'blocker', itemKey: OFFENSIVE_BLOCKER_DEFAULT_ID, quantity: 1 },
    ]),
    day('2026-08-19', 5, [{ kind: 'gold', amount: 30 }]),
    day('2026-08-20', 6, [{ kind: 'gold', amount: 35 }]),
    day('2026-08-21', 7, [{ kind: 'gold', amount: 40 }]),
    day('2026-08-22', 8, [
      { kind: 'gold', amount: 15 },
      { kind: 'frame', itemKey: 'aug_sunset_ring' },
    ]),
    day('2026-08-23', 9, [
      { kind: 'gold', amount: 15 },
      { kind: 'background', itemKey: 'aug_dusk_glow' },
    ]),
    day('2026-08-24', 10, [{ kind: 'gold', amount: 45 }]),
    day('2026-08-25', 11, [{ kind: 'gold', amount: 50 }]),
    day('2026-08-26', 12, [
      { kind: 'gold', amount: 10 },
      { kind: 'blocker', itemKey: OFFENSIVE_BLOCKER_DEFAULT_ID, quantity: 1 },
    ]),
    day('2026-08-27', 13, [{ kind: 'gold', amount: 55 }]),
    day('2026-08-28', 14, [{ kind: 'gold', amount: 60 }]),
    day('2026-08-29', 15, [
      { kind: 'gold', amount: 15 },
      { kind: 'frame', itemKey: 'aug_mint_leaf' },
    ]),
    day('2026-08-30', 16, [
      { kind: 'gold', amount: 15 },
      { kind: 'background', itemKey: 'aug_mint_lagoon' },
    ]),
    day('2026-08-31', 17, [
      { kind: 'gold', amount: 100 },
      { kind: 'blocker', itemKey: OFFENSIVE_BLOCKER_DEFAULT_ID, quantity: 1 },
    ]),
  ],
};

export const ACTIVE_CHECK_IN_CAMPAIGN = AUGUST_2026_CHECK_IN_CAMPAIGN;

export function buildCheckInReferenceKey(
  campaignId: string,
  dayKey: string,
): string {
  return `check_in_reward:${campaignId}:${dayKey}`;
}

export function summarizeCheckInRewards(rewards: CheckInReward[]): string {
  const parts: string[] = [];

  for (const reward of rewards) {
    if (reward.kind === 'gold') {
      parts.push(`${reward.amount} ouro`);
      continue;
    }
    if (reward.kind === 'blocker') {
      parts.push(
        reward.quantity > 1
          ? `${reward.quantity} bloqueadores`
          : '1 bloqueador',
      );
      continue;
    }
    if (reward.kind === 'frame') {
      parts.push('moldura');
      continue;
    }
    parts.push('fundo');
  }

  return parts.join(' + ');
}

export function primaryCheckInRewardKind(
  rewards: CheckInReward[],
): CheckInReward['kind'] {
  if (rewards.some((reward) => reward.kind === 'frame')) {
    return 'frame';
  }
  if (rewards.some((reward) => reward.kind === 'background')) {
    return 'background';
  }
  if (rewards.some((reward) => reward.kind === 'blocker')) {
    return 'blocker';
  }
  return 'gold';
}
