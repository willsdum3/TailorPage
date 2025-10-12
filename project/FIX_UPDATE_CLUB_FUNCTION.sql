-- Fix update_book_club_details to use correct column names from book_clubs table
-- The table has 'meeting_info' NOT 'meeting_time'

DROP FUNCTION IF EXISTS update_book_club_details CASCADE;

CREATE OR REPLACE FUNCTION update_book_club_details(
    auth_user_id UUID,
    club_id_param UUID,
    new_name TEXT DEFAULT NULL,
    new_description TEXT DEFAULT NULL,
    new_current_book_title TEXT DEFAULT NULL,
    new_current_book_author TEXT DEFAULT NULL,
    new_meeting_info TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT) AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN RETURN QUERY SELECT FALSE, 'User not found'::TEXT; RETURN; END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = club_id_param AND bcm.user_id = user_internal_id AND bcm.role IN ('admin', 'owner')) INTO is_admin;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN RETURN QUERY SELECT FALSE, 'Only admins can update club details'::TEXT; RETURN; END IF;
    
    -- FIXED: Use meeting_info instead of meeting_time
    UPDATE book_clubs SET
        name = COALESCE(new_name, name),
        description = COALESCE(new_description, description),
        current_book_title = COALESCE(new_current_book_title, current_book_title),
        current_book_author = COALESCE(new_current_book_author, current_book_author),
        meeting_info = COALESCE(new_meeting_info, meeting_info),
        updated_at = NOW()
    WHERE id = club_id_param;
    
    RETURN QUERY SELECT TRUE, 'Club details updated successfully'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify
SELECT 'FIXED' as status, 
       p.proname as function_name, 
       pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'update_book_club_details' 
AND n.nspname = 'public';
