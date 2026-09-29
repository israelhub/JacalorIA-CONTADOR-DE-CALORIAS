CREATE TABLE IF NOT EXISTS public.social_group_message_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id uuid NOT NULL REFERENCES public.social_group_messages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  emoji_id text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT social_group_message_reactions_message_user_key UNIQUE (message_id, user_id)
);

CREATE INDEX IF NOT EXISTS social_group_message_reactions_message_id_idx
  ON public.social_group_message_reactions (message_id);

ALTER TABLE public.social_group_message_reactions DISABLE ROW LEVEL SECURITY;
