CREATE TABLE IF NOT EXISTS food_image_analyses (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content_hash VARCHAR(64) NOT NULL,
  result JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS food_image_analyses_user_hash_unique
  ON food_image_analyses (user_id, content_hash);
