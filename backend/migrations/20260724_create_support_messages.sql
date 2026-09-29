CREATE TABLE IF NOT EXISTS support_messages (
  id UUID PRIMARY KEY,
  user_id UUID NULL REFERENCES users(id) ON DELETE SET NULL,
  subject_type VARCHAR(32) NOT NULL,
  description TEXT NOT NULL,
  contact_email VARCHAR(255) NULL,
  user_email VARCHAR(255) NULL,
  user_name VARCHAR(255) NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS support_messages_created_at_idx
  ON support_messages (created_at DESC);

CREATE INDEX IF NOT EXISTS support_messages_subject_type_idx
  ON support_messages (subject_type);
