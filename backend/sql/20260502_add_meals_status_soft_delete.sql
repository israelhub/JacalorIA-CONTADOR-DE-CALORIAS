-- Soft delete support for meals
-- Safe to run multiple times.

ALTER TABLE public.meals
ADD COLUMN IF NOT EXISTS status text;

UPDATE public.meals
SET status = 'active'
WHERE status IS NULL;

ALTER TABLE public.meals
ALTER COLUMN status SET DEFAULT 'active';

ALTER TABLE public.meals
ALTER COLUMN status SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'meals_status_check'
  ) THEN
    ALTER TABLE public.meals
    ADD CONSTRAINT meals_status_check
    CHECK (status IN ('active', 'deleted'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_meals_user_status_created_at
ON public.meals (user_id, status, created_at DESC);
