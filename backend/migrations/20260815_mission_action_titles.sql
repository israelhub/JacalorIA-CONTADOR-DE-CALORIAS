-- Títulos de missão como instrução única (sem subtítulo separado na UI).

UPDATE missions SET
  title = 'Registre uma refeição de café, almoço e jantar',
  description = 'Registre uma refeição de café, almoço e jantar',
  updated_at = NOW()
WHERE key = 'daily_three_meals';

UPDATE missions SET
  title = 'Atinja sua meta diária de proteínas',
  description = 'Atinja sua meta diária de proteínas',
  updated_at = NOW()
WHERE key = 'daily_protein_goal';

UPDATE missions SET
  title = 'Registre 15 alimentos diferentes na semana',
  description = 'Registre 15 alimentos diferentes na semana',
  updated_at = NOW()
WHERE key = 'weekly_variety_15_foods';

UPDATE missions SET
  title = 'Bata sua meta calórica em 4 dias da semana',
  description = 'Bata sua meta calórica em 4 dias da semana',
  updated_at = NOW()
WHERE key = 'weekly_goal_4_times';

UPDATE missions SET
  title = 'Registre refeições por 5 dias seguidos',
  description = 'Registre refeições por 5 dias seguidos',
  updated_at = NOW()
WHERE key = 'weekly_streak_5_days';

UPDATE missions SET
  title = 'Registre refeições em 20 dias no mês',
  description = 'Registre refeições em 20 dias no mês',
  updated_at = NOW()
WHERE key = 'monthly_objective_focus';

UPDATE missions SET
  title = 'Bata seu objetivo diário em 20 dias no mês',
  description = 'Bata seu objetivo diário em 20 dias no mês',
  updated_at = NOW()
WHERE key = 'monthly_master_consistency';

UPDATE missions SET
  title = 'Atinja todas as metas de macros em 10 dias',
  description = 'Atinja todas as metas de macros em 10 dias',
  updated_at = NOW()
WHERE key = 'monthly_macro_hunter';

UPDATE missions SET
  title = 'Bata a meta diária na sexta, sábado e domingo',
  description = 'Bata a meta diária na sexta, sábado e domingo',
  updated_at = NOW()
WHERE key = 'weekend_goal_trio';
