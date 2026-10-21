const BLOCKED_PATTERNS: RegExp[] = [
  /\b(puta|puto|putinha|putaria)\b/i,
  /\b(viado|viadinho|bicha|bichinha)\b/i,
  /\b(retardad[oa]|mongoloide|débil\s*mental|debil\s*mental)\b/i,
  /\b(filho\s*da\s*puta|fdp|vsf|vai\s*tomar\s*no\s*cu|tnc)\b/i,
  /\b(estupra|estupro|pedofil[ia]|pedo)\b/i,
  /\b(nazista|hitler|kkk)\b/i,
  /\b(mate\s*se|se\s*mate|suicida\s*logo)\b/i,
  /\b(nigger|nigga|faggot)\b/i,
];

export function normalizeChatTextForModeration(text: string): string {
  return text
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[0@]/g, 'o')
    .replace(/[1!|]/g, 'i')
    .replace(/3/g, 'e')
    .replace(/4/g, 'a')
    .replace(/5/g, 's')
    .replace(/\$/g, 's')
    .replace(/7/g, 't')
    .toLowerCase();
}

export function findChatModerationViolation(text: string): string | null {
  const normalized = normalizeChatTextForModeration(text);
  for (const pattern of BLOCKED_PATTERNS) {
    if (pattern.test(normalized) || pattern.test(text)) {
      return 'Mensagem bloqueada pela moderação do chat. Remova ofensas ou conteúdo impróprio.';
    }
  }
  return null;
}
