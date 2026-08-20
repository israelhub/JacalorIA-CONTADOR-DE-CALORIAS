-- Missões exclusivas de fim de semana (pool dinâmico, recompensas maiores).
-- O backend escolhe 2 por sábado/domingo; o seed mantém o catálogo sincronizado.

ALTER TABLE missions DROP CONSTRAINT IF EXISTS missions_type_check;
ALTER TABLE missions ADD CONSTRAINT missions_type_check
  CHECK (type = ANY (ARRAY['daily'::text, 'weekly'::text, 'monthly'::text, 'weekend'::text]));

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
VALUES
  (
    gen_random_uuid(),
    'weekend_show_up',
    'weekend',
    'Não some no fim de semana',
    'Registre pelo menos 1 refeição',
    1,
    40,
    80,
    1,
    'challenge',
    true,
    NOW(),
    NOW()
  ),
  (
    gen_random_uuid(),
    'weekend_two_logs',
    'weekend',
    'Mantém o ritmo',
    'Registre 2 refeições no dia',
    2,
    50,
    100,
    2,
    'challenge',
    true,
    NOW(),
    NOW()
  ),
  (
    gen_random_uuid(),
    'weekend_main_meals',
    'weekend',
    'Refeições principais',
    'Café, almoço ou jantar: complete 2 delas',
    2,
    55,
    110,
    3,
    'challenge',
    true,
    NOW(),
    NOW()
  ),
  (
    gen_random_uuid(),
    'weekend_hit_goal',
    'weekend',
    'Meta no fim de semana',
    'Bata sua meta calórica mesmo no sábado ou domingo',
    1,
    65,
    130,
    4,
    'challenge',
    true,
    NOW(),
    NOW()
  ),
  (
    gen_random_uuid(),
    'weekend_protein_save',
    'weekend',
    'Proteína salva o dia',
    'Atinja sua meta de proteínas',
    1,
    70,
    140,
    5,
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
