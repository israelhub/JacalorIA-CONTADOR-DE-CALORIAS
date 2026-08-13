import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  parseGeminiModelList,
  resolveModelTimeoutMs,
  shouldCooldownModel,
  thinkingConfigForModel,
  PRIMARY_MODEL_TIMEOUT_MS,
  PER_MODEL_TIMEOUT_MS,
  DEFAULT_PRIMARY_MODEL,
} from './gemini-model.util';

describe('parseGeminiModelList', () => {
  it('deduplica, corta vazios e limita a 8 modelos', () => {
    const models = parseGeminiModelList(
      ' gemini-3.5-flash-lite,gemini-3.5-flash-lite, ,gemini-3.1-flash-lite',
    );
    assert.deepEqual(models, [
      'gemini-3.5-flash-lite',
      'gemini-3.1-flash-lite',
    ]);
  });

  it('cai no primario quando a lista e vazia', () => {
    assert.deepEqual(parseGeminiModelList(' , '), [DEFAULT_PRIMARY_MODEL]);
  });
});

describe('resolveModelTimeoutMs', () => {
  it('da mais tempo ao primario e respeita o budget restante', () => {
    assert.equal(resolveModelTimeoutMs(0, 55_000), PRIMARY_MODEL_TIMEOUT_MS);
    assert.equal(resolveModelTimeoutMs(1, 55_000), PER_MODEL_TIMEOUT_MS);
    assert.equal(resolveModelTimeoutMs(0, 8_000), 8_000);
  });
});

describe('shouldCooldownModel', () => {
  it('nao esfria o modelo apos timeout local', () => {
    assert.equal(shouldCooldownModel('Timeout após 12000ms'), false);
  });

  it('esfria em 429/quota/unavailable', () => {
    assert.equal(shouldCooldownModel('HTTP 429: RESOURCE_EXHAUSTED'), true);
    assert.equal(shouldCooldownModel('quota exceeded'), true);
    assert.equal(shouldCooldownModel('HTTP 503: UNAVAILABLE'), true);
  });
});

describe('thinkingConfigForModel', () => {
  it('desliga thinking nos flash 2.5/3.x (nao lite)', () => {
    assert.deepEqual(thinkingConfigForModel('gemini-2.5-flash'), {
      thinkingBudget: 0,
    });
    assert.deepEqual(thinkingConfigForModel('gemini-3.5-flash'), {
      thinkingLevel: 'minimal',
    });
    assert.deepEqual(thinkingConfigForModel('gemini-3.6-flash'), {
      thinkingLevel: 'minimal',
    });
  });

  it('nao mexe nos lite (ja sao rapidos)', () => {
    assert.equal(thinkingConfigForModel('gemini-3.5-flash-lite'), undefined);
    assert.equal(thinkingConfigForModel('gemini-2.5-flash-lite'), undefined);
  });
});
