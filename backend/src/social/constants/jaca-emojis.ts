export const JACA_EMOJI_IDS = [
  'feliz',
  'amor',
  'fogo',
  'triste',
  'surpreso',
  'festa',
  'fome',
  'joinha',
  'sono',
  'forca',
] as const;

export const PAID_JACA_EMOJI_IDS = [
  'amor',
  'fogo',
  'festa',
  'sono',
  'forca',
] as const;

export type JacaEmojiId = (typeof JACA_EMOJI_IDS)[number];
export type PaidJacaEmojiId = (typeof PAID_JACA_EMOJI_IDS)[number];

export function isJacaEmojiId(value: string): value is JacaEmojiId {
  return (JACA_EMOJI_IDS as readonly string[]).includes(value);
}

export function isPaidJacaEmojiId(value: string): value is PaidJacaEmojiId {
  return (PAID_JACA_EMOJI_IDS as readonly string[]).includes(value);
}
