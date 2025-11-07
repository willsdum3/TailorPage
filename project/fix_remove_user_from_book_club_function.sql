-- Fix/create remove_user_from_book_club function to allow admins to remove members

DROP FUNCTION IF EXISTS remove_user_from_book_club(UUID, UUID, UUID);

CREATE OR REPLACE FUNCTION remove_user_from_book_club(
    p_auth_user_id UUID,
    p_club_id UUID,
    p_user_to_remove_id UUID
)
RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
    admin_internal_id UUID;
    user_to_remove_internal_id UUID := p_user_to_remove_id;
    is_admin BOOLEAN;
    removed_count INTEGER;
BEGIN
    -- Resolve current admin's internal ID
    admin_internal_id := get_user_internal_id(p_auth_user_id);

    IF admin_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Admin user not found';
        RETURN;
    END IF;

    -- Ensure the current user is an admin/owner of the club
    SELECT EXISTS (
        SELECT 1
        FROM book_club_members
        WHERE club_id = p_club_id
          AND user_id = admin_internal_id
          AND role IN ('admin', 'owner')
    ) INTO is_admin;

    IF NOT is_admin THEN
        RETURN QUERY SELECT FALSE, 'You do not have permission to manage this club';
        RETURN;
    END IF;

    -- Make sure the target user exists in the club
    SELECT COUNT(*) INTO removed_count
    FROM book_club_members
    WHERE club_id = p_club_id
      AND user_id = user_to_remove_internal_id;

    IF removed_count = 0 THEN
        RETURN QUERY SELECT FALSE, 'User is not a member of this club';
        RETURN;
    END IF;

    -- Remove the user from the club
    DELETE FROM book_club_members
    WHERE club_id = p_club_id
      AND user_id = user_to_remove_internal_id;

    RETURN QUERY SELECT TRUE, 'User removed from club successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION remove_user_from_book_club(UUID, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_user_from_book_club(UUID, UUID, UUID) TO anon;

SELECT 'remove_user_from_book_club function created.' AS status;
