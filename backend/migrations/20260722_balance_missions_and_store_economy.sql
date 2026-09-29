-- Balanceamento de economia de missões e loja (gamificação / retenção).
-- Escala recompensas por dificuldade e cria escada de preços com entry win + sink lendário.

UPDATE missions SET
  type = 'daily',
  title = 'Refeições completas',
  description = 'Café, almoço e jantar',
  target_value = 3,
  reward_gold = 15,
  reward_xp = 30,
  sort_order = 1,
  accent = 'action',
  is_active = true,
  updated_at = NOW()
WHERE key = 'daily_three_meals';

UPDATE missions SET
  type = 'daily',
  title = 'Atinja sua meta de proteínas',
  description = 'Consuma sua meta diária de proteína',
  target_value = 1,
  reward_gold = 25,
  reward_xp = 50,
  sort_order = 2,
  accent = 'action',
  is_active = true,
  updated_at = NOW()
WHERE key = 'daily_protein_goal';

UPDATE missions SET
  type = 'weekly',
  title = 'Variedade alimentar',
  description = 'Registre 15 alimentos diferentes',
  target_value = 15,
  reward_gold = 70,
  reward_xp = 140,
  sort_order = 1,
  accent = 'accent',
  is_active = true,
  updated_at = NOW()
WHERE key = 'weekly_variety_15_foods';

UPDATE missions SET
  type = 'weekly',
  title = 'Bata a meta 4 vezes',
  description = 'Atinja sua meta calórica em 4 dias da semana',
  target_value = 4,
  reward_gold = 90,
  reward_xp = 180,
  sort_order = 2,
  accent = 'accent',
  is_active = true,
  updated_at = NOW()
WHERE key = 'weekly_goal_4_times';

UPDATE missions SET
  type = 'weekly',
  title = 'Sequência de 5 dias',
  description = 'Registre refeições por 5 dias seguidos',
  target_value = 5,
  reward_gold = 110,
  reward_xp = 220,
  sort_order = 3,
  accent = 'accent',
  is_active = true,
  updated_at = NOW()
WHERE key = 'weekly_streak_5_days';

UPDATE missions SET
  type = 'monthly',
  title = 'Foco no objetivo',
  description = 'Registre refeições em 20 dias no mês',
  target_value = 20,
  reward_gold = 180,
  reward_xp = 360,
  sort_order = 1,
  accent = 'challenge',
  is_active = true,
  updated_at = NOW()
WHERE key = 'monthly_objective_focus';

UPDATE missions SET
  type = 'monthly',
  title = 'Mestre da consistência',
  description = 'Bata sua meta diária em 20 dias',
  target_value = 20,
  reward_gold = 250,
  reward_xp = 500,
  sort_order = 2,
  accent = 'challenge',
  is_active = true,
  updated_at = NOW()
WHERE key = 'monthly_master_consistency';

UPDATE missions SET
  type = 'monthly',
  title = 'Caçador de macros',
  description = 'Atinja todas as metas de macros em 10 dias',
  target_value = 10,
  reward_gold = 320,
  reward_xp = 640,
  sort_order = 3,
  accent = 'challenge',
  is_active = true,
  updated_at = NOW()
WHERE key = 'monthly_macro_hunter';

UPDATE store_catalog_items SET
  category = 'avatar_frame',
  name = 'Orelhas de Gato',
  description = 'Moldura suave com orelhinhas felinas.',
  price_gold = 45,
  sort_order = 10,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'cat_ears_soft';

UPDATE store_catalog_items SET
  category = 'avatar_frame',
  name = 'Cauda de Jacare',
  description = 'Moldura suave inspirada no estilo do Jaca.',
  price_gold = 70,
  sort_order = 20,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'gator_tail_fin';

UPDATE store_catalog_items SET
  category = 'avatar_frame',
  name = 'Panda Bamboo',
  description = 'Orelhas e patinhas de panda com bambu fresco.',
  price_gold = 100,
  sort_order = 30,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'panda_bamboo';

UPDATE store_catalog_items SET
  category = 'avatar_frame',
  name = 'Raposa de Outono',
  description = 'Orelhas e cauda felpuda em tons de outono.',
  price_gold = 150,
  sort_order = 40,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'fox_autumn_tail';

UPDATE store_catalog_items SET
  category = 'avatar_frame',
  name = 'Coroa de Frutas',
  description = 'Frutas e vegetais frescos ao redor do perfil.',
  price_gold = 200,
  sort_order = 50,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'fruit_ring';

UPDATE store_catalog_items SET
  category = 'avatar_frame',
  name = 'Chama da Sequencia',
  description = 'Anel em brasa com chamas da ofensiva.',
  price_gold = 350,
  sort_order = 60,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'fire_streak';

UPDATE store_catalog_items SET
  category = 'avatar_frame',
  name = 'Ouro Real',
  description = 'Anel dourado com coroa, gemas e moedas.',
  price_gold = 2000,
  sort_order = 70,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'royal_gold';

UPDATE store_catalog_items SET
  category = 'avatar_background',
  name = 'Sky',
  description = 'Ceú aberto com tons azuis.',
  price_gold = 55,
  sort_order = 10,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'sky';

UPDATE store_catalog_items SET
  category = 'avatar_background',
  name = 'Sunset Orbit',
  description = 'Por do sol com orbitas suaves.',
  price_gold = 85,
  sort_order = 20,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'sunset_orbit';

UPDATE store_catalog_items SET
  category = 'avatar_background',
  name = 'Jungle Neon',
  description = 'Selva vibrante com brilho neon.',
  price_gold = 160,
  sort_order = 30,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'jungle_neon';

UPDATE store_catalog_items SET
  category = 'avatar_background',
  name = 'Pantano',
  description = 'Atmosfera verde e misteriosa.',
  price_gold = 220,
  sort_order = 40,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'pantano';

UPDATE store_catalog_items SET
  category = 'avatar_background',
  name = 'Aurora Grid',
  description = 'Aurora boreal com grade futurista.',
  price_gold = 400,
  sort_order = 50,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'aurora_grid';

UPDATE store_catalog_items SET
  category = 'offensive_blocker',
  name = 'Bloqueador de sequência',
  description = 'Protege sua ofensiva por 1 dia perdido.',
  price_gold = 100,
  sort_order = 10,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'offensive_guard';

UPDATE store_catalog_items SET
  category = 'streak_restore',
  name = 'Restaurar sequências perdidas até então',
  description = 'Usa bloqueadores para recuperar dias perdidos.',
  price_gold = 0,
  sort_order = 20,
  is_active = true,
  updated_at = NOW()
WHERE item_key = 'streak_restore';

UPDATE store_catalog_items SET
  is_active = false,
  updated_at = NOW()
WHERE item_key IN ('emerald_guard', 'crystal_champion', 'cosmic_blossom');
