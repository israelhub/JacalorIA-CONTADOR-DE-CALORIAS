import assert from 'node:assert/strict';
import {
  CHECK_IN_CAMPAIGNS,
  resolveCheckInCampaign,
} from './check-in.campaign';

const upcomingIds = ['oct2026', 'nov2026', 'dec2026', 'jan2027', 'feb2027'];

assert.equal(resolveCheckInCampaign('2026-09-30'), null);
assert.equal(resolveCheckInCampaign('2026-08-31')?.id, 'aug2026');
assert.equal(resolveCheckInCampaign('2026-10-01')?.id, 'oct2026');
assert.equal(resolveCheckInCampaign('2027-02-28')?.id, 'feb2027');
assert.equal(resolveCheckInCampaign('2027-03-01'), null);

for (const id of upcomingIds) {
  const campaign = CHECK_IN_CAMPAIGNS.find((item) => item.id === id);
  assert.ok(campaign, id);
  const finale = campaign.days[campaign.days.length - 1];
  assert.equal(campaign.days[0].dayKey, campaign.startDayKey);
  assert.equal(finale.dayKey, campaign.endDayKey);
  assert.equal(campaign.days.length, Number(campaign.endDayKey.slice(8)));

  const keys = campaign.days.map((day) => day.dayKey);
  assert.equal(new Set(keys).size, keys.length);

  assert.deepEqual(
    finale.rewards.map((reward) => reward.kind),
    ['gold', 'blocker'],
  );
  const finaleGold = finale.rewards[0];
  assert.equal(finaleGold.kind, 'gold');
  assert.equal(finaleGold.kind === 'gold' ? finaleGold.amount : 0, 100);

  const blockerDays = campaign.days.filter((day) =>
    day.rewards.some((reward) => reward.kind === 'blocker'),
  );
  assert.equal(blockerDays.length, 3);
}

const february = resolveCheckInCampaign('2027-02-15');
assert.equal(february?.days.length, 28);
assert.equal(february?.title, 'Recompensas de fevereiro');
