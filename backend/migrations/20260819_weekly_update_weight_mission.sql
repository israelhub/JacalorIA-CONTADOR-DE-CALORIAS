-- Missão semanal 0/1 de atualizar o peso, com ouro/XP redistribuídos das outras semanais.

UPDATE missions SET
  reward_gold = 60,
  reward_xp = 120,
  updated_at = NOW()
WHERE key = 'weekly_variety_15_foods';

UPDATE missions SET
  reward_gold = 80,
  reward_xp = 160,
  updated_at = NOW()
WHERE key = 'weekly_goal_4_times';

UPDATE missions SET
  reward_gold = 100,
  reward_xp = 200,
  updated_at = NOW()
WHERE key = 'weekly_streak_5_days';

INSERT INTO missions (
  id,
  key,
  type,
  title,
  description,
  target_value,
  reward_gold,
  reward_xp,
  sort_order,
  accent,
  is_active,
  created_at,
  updated_at
)
VALUES (
  gen_random_uuid(),
  'weekly_update_weight',
  'weekly',
  'Atualize o seu peso na semana',
  'Atualize o seu peso na semana',
  1,
  30,
  60,
  4,
  'accent',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (key) DO UPDATE SET
  type = EXCLUDED.type,
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  target_value = EXCLUDED.target_value,
  reward_gold = EXCLUDED.reward_gold,
  reward_xp = EXCLUDED.reward_xp,
  sort_order = EXCLUDED.sort_order,
  accent = EXCLUDED.accent,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();
