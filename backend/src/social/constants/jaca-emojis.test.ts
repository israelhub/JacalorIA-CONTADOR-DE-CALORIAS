import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { isJacaEmojiId, isPaidJacaEmojiId } from './jaca-emojis';

describe('isJacaEmojiId', () => {
  it('aceita os emojis do catalogo', () => {
    assert.equal(isJacaEmojiId('feliz'), true);
    assert.equal(isJacaEmojiId('forca'), true);
  });

  it('rejeita ids desconhecidos', () => {
    assert.equal(isJacaEmojiId(''), false);
    assert.equal(isJacaEmojiId('fire'), false);
  });
});

describe('isPaidJacaEmojiId', () => {
  it('marca as 5 figurinhas da loja', () => {
    assert.equal(isPaidJacaEmojiId('amor'), true);
    assert.equal(isPaidJacaEmojiId('fogo'), true);
    assert.equal(isPaidJacaEmojiId('festa'), true);
    assert.equal(isPaidJacaEmojiId('sono'), true);
    assert.equal(isPaidJacaEmojiId('forca'), true);
  });

  it('mantem as 5 figurinhas livres', () => {
    assert.equal(isPaidJacaEmojiId('feliz'), false);
    assert.equal(isPaidJacaEmojiId('triste'), false);
    assert.equal(isPaidJacaEmojiId('surpreso'), false);
    assert.equal(isPaidJacaEmojiId('fome'), false);
    assert.equal(isPaidJacaEmojiId('joinha'), false);
  });
});
