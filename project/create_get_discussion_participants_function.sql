-- Create function to fetch discussion participants with user details
-- Ensures only participants or the discussion creator can view the list

CREATE OR REPLACE FUNCTION get_discussion_participants(
    p_auth_user_id UUID,
    p_discussion_id UUID
)
RETURNS TABLE (
    user_id UUID,
    name TEXT,
    username TEXT,
    avatar_url TEXT
) AS $$
DECLARE
    v_user_internal_id UUID;
BEGIN
    -- Resolve internal user ID
    v_user_internal_id := get_user_internal_id(p_auth_user_id);

    IF v_user_internal_id IS NULL THEN
        RETURN;
    END IF;

    -- Ensure the requesting user has access (participant or creator)
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members dm_check
        WHERE dm_check.discussion_id = p_discussion_id
          AND dm_check.user_id = v_user_internal_id
    ) AND NOT EXISTS (
        SELECT 1 FROM discussions
        WHERE id = p_discussion_id
          AND created_by = v_user_internal_id
    ) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        u.id AS user_id,
        COALESCE(NULLIF(BTRIM(u.name), ''), NULLIF(BTRIM(u.username), ''), 'Unknown') AS name,
        u.username,
        u.avatar_url
    FROM discussion_members dm
    JOIN users u ON u.id = dm.user_id
    WHERE dm.discussion_id = p_discussion_id
    ORDER BY name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

GRANT EXECUTE ON FUNCTION get_discussion_participants(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_discussion_participants(UUID, UUID) TO anon;

