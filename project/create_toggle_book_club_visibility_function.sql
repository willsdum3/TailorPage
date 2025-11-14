-- Function to toggle book club visibility (public/private)
-- Ensures requester is a club admin/owner

DROP FUNCTION IF EXISTS toggle_book_club_visibility(UUID, UUID, BOOLEAN);

CREATE OR REPLACE FUNCTION toggle_book_club_visibility(
    p_auth_user_id UUID,
    p_club_id UUID,
    p_is_public BOOLEAN
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_user_internal_id UUID;
    v_is_admin BOOLEAN;
BEGIN
    -- Resolve internal user id
    v_user_internal_id := get_user_internal_id(p_auth_user_id);

    IF v_user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found';
        RETURN;
    END IF;

    -- Ensure requester is an admin or owner of the club
    SELECT EXISTS(
        SELECT 1
        FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id
          AND bcm.user_id = v_user_internal_id
          AND bcm.role IN ('admin', 'owner')
    ) INTO v_is_admin;

    IF NOT v_is_admin THEN
        RETURN QUERY SELECT FALSE, 'Only club admins can update visibility';
        RETURN;
    END IF;

    -- Update visibility
    UPDATE book_clubs
    SET is_public = p_is_public
    WHERE id = p_club_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Book club not found';
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE,
        CASE WHEN p_is_public THEN 'Club is now public' ELSE 'Club is now private' END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

GRANT EXECUTE ON FUNCTION toggle_book_club_visibility(UUID, UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_book_club_visibility(UUID, UUID, BOOLEAN) TO anon;

