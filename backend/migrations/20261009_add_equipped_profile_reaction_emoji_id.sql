ALTER TABLE users
  ADD COLUMN IF NOT EXISTS equipped_profile_reaction_emoji_id TEXT NULL;
