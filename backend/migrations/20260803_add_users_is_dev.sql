ALTER TABLE users
  ADD COLUMN IF NOT EXISTS is_dev BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE users
SET is_dev = TRUE
WHERE id = '373c4b29-7d6a-44ba-b714-23de530c1c6d'
   OR email = 'jooaopedro1980@gmail.com';
