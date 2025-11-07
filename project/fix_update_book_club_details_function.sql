-- Fix or create the update_book_club_details function used by admins to edit club info

DROP FUNCTION IF EXISTS update_book_club_details(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION update_book_club_details(
    p_auth_user_id UUID,
    p_club_id UUID,
    p_new_name TEXT DEFAULT NULL,
    p_new_description TEXT DEFAULT NULL,
    p_new_current_book_title TEXT DEFAULT NULL,
    p_new_current_book_author TEXT DEFAULT NULL,
    p_new_meeting_info TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
BEGIN
    -- Get internal ID for current user
    user_internal_id := get_user_internal_id(p_auth_user_id);

    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found';
        RETURN;
    END IF;

    -- Ensure the user is an admin/owner of the club
    SELECT EXISTS (
        SELECT 1
        FROM book_club_members
        WHERE club_id = p_club_id
          AND user_id = user_internal_id
          AND role IN ('admin', 'owner')
    ) INTO is_admin;

    IF NOT is_admin THEN
        RETURN QUERY SELECT FALSE, 'You do not have permission to edit this club';
        RETURN;
    END IF;

    -- Perform the update with provided values (trim empty strings)
    UPDATE book_clubs
    SET
        name = COALESCE(NULLIF(TRIM(p_new_name), ''), name),
        description = COALESCE(NULLIF(TRIM(p_new_description), ''), description),
        current_book_title = COALESCE(NULLIF(TRIM(p_new_current_book_title), ''), current_book_title),
        current_book_author = COALESCE(NULLIF(TRIM(p_new_current_book_author), ''), current_book_author),
        meeting_info = COALESCE(NULLIF(TRIM(p_new_meeting_info), ''), meeting_info),
        updated_at = NOW()
    WHERE id = p_club_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Club not found';
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Book club updated successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION update_book_club_details(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION update_book_club_details(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT) TO anon;

SELECT 'update_book_club_details function created.' AS status;
