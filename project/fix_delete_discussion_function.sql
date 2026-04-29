-- Ensure delete_discussion RPC exists
-- Run in Supabase SQL Editor
-- Note: PostgreSQL function identity is based on name + arg types, not arg names.
-- So we cannot keep both (auth_user_id, discussion_id) and
-- (p_auth_user_id, p_discussion_id) simultaneously for UUID, UUID.

DROP FUNCTION IF EXISTS public.delete_discussion(UUID, UUID);

CREATE OR REPLACE FUNCTION public.delete_discussion(
  p_auth_user_id UUID,
  p_discussion_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT u.id
  INTO v_user_id
  FROM public.users u
  WHERE u.auth_user_id = p_auth_user_id;

  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'User not found');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.discussions d
    WHERE d.id = p_discussion_id
      AND d.created_by = v_user_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Only the creator can delete this discussion');
  END IF;

  -- Explicit cleanup for schemas without ON DELETE CASCADE.
  DELETE FROM public.discussion_messages WHERE discussion_id = p_discussion_id;
  DELETE FROM public.discussion_participants WHERE discussion_id = p_discussion_id;
  DELETE FROM public.discussions WHERE id = p_discussion_id;

  RETURN jsonb_build_object('success', true);
END;
$$;
