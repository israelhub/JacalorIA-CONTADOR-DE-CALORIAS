CREATE TABLE IF NOT EXISTS public.water_intake_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  recorded_at date NOT NULL,
  milliliters integer NOT NULL CHECK (milliliters >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, recorded_at)
);

CREATE INDEX IF NOT EXISTS water_intake_entries_user_recorded_idx
  ON public.water_intake_entries (user_id, recorded_at DESC);

ALTER TABLE public.water_intake_entries ENABLE ROW LEVEL SECURITY;
