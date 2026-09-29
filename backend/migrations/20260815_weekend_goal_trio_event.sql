-- Evento de fim de semana: meta diária em sexta, sábado e domingo.

UPDATE missions
SET is_active = false,
    updated_at = NOW()
WHERE type = 'weekend'
  AND key <> 'weekend_goal_trio';

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
  'weekend_goal_trio',
  'weekend',
  'Trio do fim de semana',
  'Bata a meta diária na sexta, sábado e domingo',
  3,
  120,
  240,
  1,
  'challenge',
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
