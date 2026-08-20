ALTER TABLE users
  ADD COLUMN IF NOT EXISTS purchased_jaca_emoji_ids JSONB NOT NULL DEFAULT '[]'::jsonb;
