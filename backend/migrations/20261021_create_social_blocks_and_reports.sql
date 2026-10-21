CREATE TABLE IF NOT EXISTS public.social_user_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT social_user_blocks_no_self CHECK (blocker_id <> blocked_id),
  CONSTRAINT social_user_blocks_unique UNIQUE (blocker_id, blocked_id)
);

CREATE INDEX IF NOT EXISTS social_user_blocks_blocker_id_idx
  ON public.social_user_blocks (blocker_id);

CREATE INDEX IF NOT EXISTS social_user_blocks_blocked_id_idx
  ON public.social_user_blocks (blocked_id);

CREATE TABLE IF NOT EXISTS public.social_content_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_type VARCHAR(16) NOT NULL,
  target_user_id UUID NULL REFERENCES public.users(id) ON DELETE SET NULL,
  message_id UUID NULL,
  group_id UUID NULL,
  reason VARCHAR(32) NOT NULL,
  details TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS social_content_reports_reporter_id_idx
  ON public.social_content_reports (reporter_id);

CREATE INDEX IF NOT EXISTS social_content_reports_created_at_idx
  ON public.social_content_reports (created_at DESC);
