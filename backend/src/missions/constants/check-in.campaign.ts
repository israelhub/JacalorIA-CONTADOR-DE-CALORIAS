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

function day(
  dayKey: string,
  dayIndex: number,
  rewards: CheckInReward[],
): CheckInDayDefinition {
  return { dayKey, dayIndex, rewards };
}

const BLOCKER_REWARD: CheckInReward = {
  kind: 'blocker',
  itemKey: OFFENSIVE_BLOCKER_DEFAULT_ID,
  quantity: 1,
};

/**
 * Campanha de check-in diário de 15 a 31 de agosto/2026.
 * Recompensas misturam ouro, bloqueador, moldura e fundo.
 */
export const AUGUST_2026_CHECK_IN_CAMPAIGN: CheckInCampaignDefinition = {
  id: 'aug2026',
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
      BLOCKER_REWARD,
    ]),
    day('2026-08-19', 5, [{ kind: 'gold', amount: 30 }]),
    day('2026-08-20', 6, [{ kind: 'gold', amount: 35 }]),
    day('2026-08-21', 7, [{ kind: 'gold', amount: 40 }]),
    day('2026-08-22', 8, [{ kind: 'gold', amount: 45 }]),
    day('2026-08-23', 9, [
      { kind: 'gold', amount: 15 },
      { kind: 'background', itemKey: 'aug_dusk_glow' },
    ]),
    day('2026-08-24', 10, [
      { kind: 'gold', amount: 15 },
      { kind: 'frame', itemKey: 'aug_sunset_ring' },
    ]),
    day('2026-08-25', 11, [{ kind: 'gold', amount: 50 }]),
    day('2026-08-26', 12, [
      { kind: 'gold', amount: 10 },
      BLOCKER_REWARD,
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
      BLOCKER_REWARD,
    ]),
  ],
};

type MonthCampaignSeed = {
  id: string;
  monthName: string;
  year: number;
  month: number;
};

const UPCOMING_MONTHS: MonthCampaignSeed[] = [
  { id: 'oct2026', monthName: 'outubro', year: 2026, month: 10 },
  { id: 'nov2026', monthName: 'novembro', year: 2026, month: 11 },
  { id: 'dec2026', monthName: 'dezembro', year: 2026, month: 12 },
  { id: 'jan2027', monthName: 'janeiro', year: 2027, month: 1 },
  { id: 'feb2027', monthName: 'fevereiro', year: 2027, month: 2 },
];

function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

function ordinaryGold(dayOfMonth: number, length: number): number {
  if (length <= 1) {
    return 15;
  }
  const progress = (dayOfMonth - 1) / (length - 1);
  return 15 + Math.round(progress * 9) * 5;
}

function blockerDayOfMonth(templateDay: number, length: number): number {
  const raw = Math.round((templateDay / 17) * length);
  return Math.max(1, Math.min(length - 1, raw));
}

function buildMonthCampaign(seed: MonthCampaignSeed): CheckInCampaignDefinition {
  const length = daysInMonth(seed.year, seed.month);
  const month = String(seed.month).padStart(2, '0');
  const blockerDays = new Set([
    blockerDayOfMonth(4, length),
    blockerDayOfMonth(12, length),
  ]);
  const days: CheckInDayDefinition[] = [];

  for (let dayOfMonth = 1; dayOfMonth <= length; dayOfMonth += 1) {
    const dayKey = `${seed.year}-${month}-${String(dayOfMonth).padStart(2, '0')}`;
    const isFinale = dayOfMonth === length;
    const rewards: CheckInReward[] = isFinale
      ? [{ kind: 'gold', amount: 100 }, BLOCKER_REWARD]
      : blockerDays.has(dayOfMonth)
        ? [{ kind: 'gold', amount: 10 }, BLOCKER_REWARD]
        : [{ kind: 'gold', amount: ordinaryGold(dayOfMonth, length) }];

    days.push(day(dayKey, dayOfMonth, rewards));
  }

  return {
    id: seed.id,
    title: `Recompensas de ${seed.monthName}`,
    subtitle: `Ganhe recompensas até o fim de ${seed.monthName}`,
    startDayKey: days[0].dayKey,
    endDayKey: days[days.length - 1].dayKey,
    days,
  };
}

export const CHECK_IN_CAMPAIGNS: CheckInCampaignDefinition[] = [
  AUGUST_2026_CHECK_IN_CAMPAIGN,
  ...UPCOMING_MONTHS.map(buildMonthCampaign),
];

export function resolveCheckInCampaign(
  dayKey: string,
): CheckInCampaignDefinition | null {
  return (
    CHECK_IN_CAMPAIGNS.find(
      (campaign) => dayKey >= campaign.startDayKey && dayKey <= campaign.endDayKey,
    ) ?? null
  );
}

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
