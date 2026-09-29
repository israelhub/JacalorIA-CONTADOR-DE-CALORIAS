-- Modelo ideal: vínculo usuário↔missão e histórico de compras da loja.
-- Ledger financeiro (user_currency_transactions) permanece a fonte de ouro/XP.

CREATE TABLE IF NOT EXISTS user_missions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  mission_key VARCHAR(255) NOT NULL,
  period_key VARCHAR(64) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'in_progress',
  progress_current INTEGER NOT NULL DEFAULT 0,
  progress_target INTEGER NOT NULL DEFAULT 1,
  completed_at TIMESTAMPTZ,
  reward_credited_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_user_missions_status CHECK (status IN ('in_progress', 'completed')),
  CONSTRAINT uniq_user_missions_period UNIQUE (user_id, mission_id, period_key)
);

CREATE INDEX IF NOT EXISTS idx_user_missions_user_status
  ON user_missions (user_id, status);

CREATE INDEX IF NOT EXISTS idx_user_missions_user_period
  ON user_missions (user_id, period_key);

CREATE TABLE IF NOT EXISTS store_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  catalog_item_id UUID REFERENCES store_catalog_items(id) ON DELETE SET NULL,
  item_key VARCHAR(255) NOT NULL,
  category VARCHAR(64) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  price_gold INTEGER NOT NULL DEFAULT 0,
  currency_transaction_id UUID REFERENCES user_currency_transactions(id) ON DELETE SET NULL,
  acquire_source VARCHAR(32) NOT NULL DEFAULT 'purchase',
  reference_key VARCHAR(255),
  purchased_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_store_purchases_quantity CHECK (quantity > 0),
  CONSTRAINT chk_store_purchases_acquire_source
    CHECK (acquire_source IN ('purchase', 'check_in', 'migration'))
);

CREATE INDEX IF NOT EXISTS idx_store_purchases_user_item
  ON store_purchases (user_id, item_key);

CREATE INDEX IF NOT EXISTS idx_store_purchases_user_category
  ON store_purchases (user_id, category);

CREATE UNIQUE INDEX IF NOT EXISTS uniq_store_purchases_user_reference
  ON store_purchases (user_id, reference_key)
  WHERE reference_key IS NOT NULL;

-- Backfill: conclusões de missão a partir do ledger (reference_key = mission_reward:key:period).
INSERT INTO user_missions (
  user_id,
  mission_id,
  mission_key,
  period_key,
  status,
  progress_current,
  progress_target,
  completed_at,
  reward_credited_at,
  created_at,
  updated_at
)
SELECT
  t.user_id,
  m.id,
  m.key,
  split_part(t.reference_key, ':', 3),
  'completed',
  GREATEST(1, m.target_value),
  GREATEST(1, m.target_value),
  MIN(t.created_at),
  MIN(t.created_at),
  MIN(t.created_at),
  NOW()
FROM user_currency_transactions t
INNER JOIN missions m
  ON m.key = split_part(t.reference_key, ':', 2)
WHERE t.source_type = 'mission_reward'
  AND t.reference_key LIKE 'mission_reward:%:%'
  AND NULLIF(split_part(t.reference_key, ':', 3), '') IS NOT NULL
GROUP BY t.user_id, m.id, m.key, m.target_value, split_part(t.reference_key, ':', 3)
ON CONFLICT (user_id, mission_id, period_key) DO UPDATE
SET
  status = 'completed',
  progress_current = GREATEST(user_missions.progress_current, EXCLUDED.progress_current),
  progress_target = GREATEST(user_missions.progress_target, EXCLUDED.progress_target),
  completed_at = COALESCE(user_missions.completed_at, EXCLUDED.completed_at),
  reward_credited_at = COALESCE(user_missions.reward_credited_at, EXCLUDED.reward_credited_at),
  updated_at = NOW();

-- Backfill: compras cosméticas a partir dos JSONB do usuário.
INSERT INTO store_purchases (
  user_id,
  catalog_item_id,
  item_key,
  category,
  quantity,
  price_gold,
  acquire_source,
  reference_key,
  purchased_at,
  created_at,
  updated_at
)
SELECT
  u.id,
  sci.id,
  item_key,
  COALESCE(sci.category, 'avatar_frame'),
  1,
  COALESCE(sci.price_gold, 0),
  'migration',
  'migration:avatar_frame:' || item_key,
  COALESCE(u.updated_at, NOW()),
  COALESCE(u.updated_at, NOW()),
  NOW()
FROM users u
CROSS JOIN LATERAL jsonb_array_elements_text(
  COALESCE(u.purchased_avatar_frame_ids, '[]'::jsonb)
) AS item_key
LEFT JOIN store_catalog_items sci ON sci.item_key = item_key
WHERE NULLIF(BTRIM(item_key), '') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO store_purchases (
  user_id,
  catalog_item_id,
  item_key,
  category,
  quantity,
  price_gold,
  acquire_source,
  reference_key,
  purchased_at,
  created_at,
  updated_at
)
SELECT
  u.id,
  sci.id,
  item_key,
  COALESCE(sci.category, 'avatar_background'),
  1,
  COALESCE(sci.price_gold, 0),
  'migration',
  'migration:avatar_background:' || item_key,
  COALESCE(u.updated_at, NOW()),
  COALESCE(u.updated_at, NOW()),
  NOW()
FROM users u
CROSS JOIN LATERAL jsonb_array_elements_text(
  COALESCE(u.purchased_avatar_background_ids, '[]'::jsonb)
) AS item_key
LEFT JOIN store_catalog_items sci ON sci.item_key = item_key
WHERE NULLIF(BTRIM(item_key), '') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO store_purchases (
  user_id,
  catalog_item_id,
  item_key,
  category,
  quantity,
  price_gold,
  acquire_source,
  reference_key,
  purchased_at,
  created_at,
  updated_at
)
SELECT
  u.id,
  sci.id,
  item_key,
  COALESCE(sci.category, 'jaca_emoji'),
  1,
  COALESCE(sci.price_gold, 0),
  'migration',
  'migration:jaca_emoji:' || item_key,
  COALESCE(u.updated_at, NOW()),
  COALESCE(u.updated_at, NOW()),
  NOW()
FROM users u
CROSS JOIN LATERAL jsonb_array_elements_text(
  COALESCE(u.purchased_jaca_emoji_ids, '[]'::jsonb)
) AS item_key
LEFT JOIN store_catalog_items sci ON sci.item_key = item_key
WHERE NULLIF(BTRIM(item_key), '') IS NOT NULL
ON CONFLICT DO NOTHING;

-- Backfill: débitos históricos da loja no ledger (complementa JSON e cobre edge cases).
INSERT INTO store_purchases (
  user_id,
  catalog_item_id,
  item_key,
  category,
  quantity,
  price_gold,
  currency_transaction_id,
  acquire_source,
  reference_key,
  purchased_at,
  created_at,
  updated_at
)
SELECT
  t.user_id,
  sci.id,
  COALESCE(NULLIF(BTRIM(t.source_id), ''), sci.item_key),
  CASE t.source_type
    WHEN 'avatar_frame_purchase' THEN 'avatar_frame'
    WHEN 'avatar_background_purchase' THEN 'avatar_background'
    WHEN 'jaca_emoji_purchase' THEN 'jaca_emoji'
    WHEN 'offensive_blocker_purchase' THEN 'offensive_blocker'
    WHEN 'offensive_blocker_auto_purchase' THEN 'offensive_blocker'
    WHEN 'streak_restore_purchase' THEN 'streak_restore'
    ELSE COALESCE(sci.category, 'avatar_frame')
  END,
  GREATEST(
    1,
    COALESCE((t.metadata->>'quantity')::INTEGER, 1)
  ),
  ABS(t.amount_signed),
  t.id,
  'migration',
  COALESCE(
    NULLIF(BTRIM(t.reference_key), ''),
    'migration:ledger:' || t.id::TEXT
  ),
  t.created_at,
  t.created_at,
  NOW()
FROM user_currency_transactions t
LEFT JOIN store_catalog_items sci
  ON sci.item_key = NULLIF(BTRIM(t.source_id), '')
WHERE t.type = 'debit'
  AND t.currency = 'gold'
  AND t.source_type IN (
    'avatar_frame_purchase',
    'avatar_background_purchase',
    'jaca_emoji_purchase',
    'offensive_blocker_purchase',
    'offensive_blocker_auto_purchase',
    'streak_restore_purchase'
  )
  AND NULLIF(BTRIM(COALESCE(t.source_id, '')), '') IS NOT NULL
ON CONFLICT DO NOTHING;
