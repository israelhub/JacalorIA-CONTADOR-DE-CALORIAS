CREATE TABLE IF NOT EXISTS notification_broadcasts (
  id UUID PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  channel VARCHAR(16) NOT NULL,
  audience VARCHAR(16) NOT NULL DEFAULT 'all',
  recipient_count INTEGER NOT NULL DEFAULT 0,
  email_sent_count INTEGER NOT NULL DEFAULT 0,
  email_failed_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notification_broadcasts_created_at_idx
  ON notification_broadcasts (created_at DESC);

CREATE TABLE IF NOT EXISTS user_notifications (
  id UUID PRIMARY KEY,
  broadcast_id UUID NOT NULL REFERENCES notification_broadcasts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at TIMESTAMPTZ NULL,
  dismissed_at TIMESTAMPTZ NULL,
  delivered_in_app_at TIMESTAMPTZ NULL,
  CONSTRAINT user_notifications_broadcast_user_uq UNIQUE (broadcast_id, user_id)
);

CREATE INDEX IF NOT EXISTS user_notifications_user_id_idx
  ON user_notifications (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS user_notifications_user_active_idx
  ON user_notifications (user_id)
  WHERE dismissed_at IS NULL;
