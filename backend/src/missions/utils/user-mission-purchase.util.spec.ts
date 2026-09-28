import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  buildMissionRewardReferenceKey,
  buildStorePurchaseReferenceKey,
  mergeOwnedItemKeys,
  parseMissionRewardReferenceKey,
  resolveUserMissionStatus,
} from './user-mission-purchase.util';

describe('user-mission-purchase.util', () => {
  it('monta e parseia reference_key de recompensa de missão', () => {
    const key = buildMissionRewardReferenceKey('daily_three_meals', '2026-09-28');
    assert.equal(key, 'mission_reward:daily_three_meals:2026-09-28');

    const parsed = parseMissionRewardReferenceKey(key);
    assert.deepEqual(parsed, {
      missionKey: 'daily_three_meals',
      periodKey: '2026-09-28',
    });
  });

  it('ignora reference_key inválida', () => {
    assert.equal(parseMissionRewardReferenceKey(null), null);
    assert.equal(parseMissionRewardReferenceKey('avatar_frame_purchase:x'), null);
    assert.equal(parseMissionRewardReferenceKey('mission_reward:only'), null);
  });

  it('marca missão como completed quando progresso atinge o alvo', () => {
    assert.equal(
      resolveUserMissionStatus({ progressCurrent: 3, progressTarget: 3 }),
      'completed',
    );
    assert.equal(
      resolveUserMissionStatus({ progressCurrent: 1, progressTarget: 3 }),
      'in_progress',
    );
    assert.equal(
      resolveUserMissionStatus({
        progressCurrent: 0,
        progressTarget: 3,
        alreadyCompleted: true,
      }),
      'completed',
    );
  });

  it('mescla inventário da tabela de compras com fallback JSON', () => {
    assert.deepEqual(mergeOwnedItemKeys(['frame_a', ' frame_b '], ['frame_b', 'frame_c']), [
      'frame_a',
      'frame_b',
      'frame_c',
    ]);
  });

  it('monta reference_key de compra da loja', () => {
    assert.equal(
      buildStorePurchaseReferenceKey({
        sourceType: 'avatar_frame_purchase',
        itemKey: 'gold_ring',
      }),
      'avatar_frame_purchase:gold_ring',
    );
  });
});
