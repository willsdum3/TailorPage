-- Fix get_user_club_invitations so invited users can view and act on pending invites

DROP FUNCTION IF EXISTS get_user_club_invitations(UUID);

CREATE OR REPLACE FUNCTION get_user_club_invitations(
    p_auth_user_id UUID
)
RETURNS TABLE (
    id UUID,
    club_id UUID,
    club_name TEXT,
    club_description TEXT,
    inviter_name TEXT,
    inviter_username TEXT,
    inviter_avatar_url TEXT,
    message TEXT,
    status TEXT,
    created_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_internal_id UUID;
BEGIN
    -- Resolve the invited user's internal ID
    v_user_internal_id := get_user_internal_id(p_auth_user_id);

    IF v_user_internal_id IS NULL THEN
        RETURN;
    END IF;

    -- Return active invitations for the user
    RETURN QUERY
    SELECT
        ci.id,
        ci.club_id,
        bc.name AS club_name,
        bc.description AS club_description,
        COALESCE(
            NULLIF(btrim(inviter.name), ''),
            NULLIF(btrim(inviter.username), ''),
            'Unknown'
        ) AS inviter_name,
        NULLIF(btrim(inviter.username), '') AS inviter_username,
        inviter.avatar_url AS inviter_avatar_url,
        ci.message,
        LOWER(TRIM(ci.status)) AS status,
        ci.created_at,
        ci.expires_at
    FROM club_invitations ci
    JOIN book_clubs bc ON bc.id = ci.club_id
    LEFT JOIN users inviter ON inviter.id = ci.inviter_id
    WHERE ci.invitee_id = v_user_internal_id
      AND LOWER(TRIM(ci.status)) = 'pending'
      AND (ci.expires_at IS NULL OR ci.expires_at >= NOW())
    ORDER BY ci.created_at DESC;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth;

