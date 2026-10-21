import { findChatModerationViolation } from './chat-moderation.util';

describe('findChatModerationViolation', () => {
  it('bloqueia ofensa comum', () => {
    expect(findChatModerationViolation('vai tomar no cu')).toBeTruthy();
  });

  it('permite texto normal', () => {
    expect(findChatModerationViolation('Bora treinar amanhã')).toBeNull();
  });
});
