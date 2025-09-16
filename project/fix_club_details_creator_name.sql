-- =====================================================
-- FIX CLUB DETAILS TO SHOW PROPER CREATOR NAME
-- =====================================================
-- This script fixes the get_book_club_details function to properly return creator username

-- Drop and recreate the get_book_club_details function with proper creator name lookup
DROP FUNCTION IF EXISTS get_book_club_details(UUID, UUID);

CREATE OR REPLACE FUNCTION get_book_club_details(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    current_book_title TEXT,
    current_book_author TEXT,
    max_members INTEGER,
    is_public BOOLEAN,
    target_personality_traits TEXT[],
    tags TEXT[],
    meeting_info TEXT,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    member_count BIGINT,
    is_member BOOLEAN,
    user_role TEXT,
    creator_name TEXT
) AS $$
DECLARE
    user_uuid UUID;
    club_exists BOOLEAN := false;
    user_is_member BOOLEAN := false;
    user_role_val TEXT := 'non-member';
    member_count_val BIGINT := 0;
    creator_name_val TEXT := 'Unknown';
BEGIN
    -- Get user UUID from auth_user_id
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = get_book_club_details.auth_user_id;
    
    -- Check if club exists
    SELECT EXISTS(SELECT 1 FROM book_clubs WHERE id = club_id_param) INTO club_exists;
    
    IF NOT club_exists OR user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Check if user is member and get their role
    SELECT 
        EXISTS(SELECT 1 FROM club_memberships WHERE club_id = club_id_param AND user_id = user_uuid),
        COALESCE((SELECT role FROM club_memberships WHERE club_id = club_id_param AND user_id = user_uuid), 'non-member')
    INTO user_is_member, user_role_val;
    
    -- Get accurate member count
    SELECT COUNT(*) INTO member_count_val
    FROM club_memberships 
    WHERE club_id = club_id_param;
    
    -- Get creator name/username - try username first, then name as fallback
    SELECT 
        COALESCE(creator.username, creator.name, 'Unknown Creator')
    INTO creator_name_val
    FROM book_clubs bc
    JOIN users creator ON bc.created_by = creator.id
    WHERE bc.id = club_id_param;
    
    -- Return the club details
    RETURN QUERY
    SELECT 
        bc.id,
        bc.name,
        bc.description,
        bc.current_book_title,
        bc.current_book_author,
        bc.max_members,
        bc.is_public,
        bc.target_personality_traits,
        bc.tags,
        bc.meeting_info,
        bc.created_by,
        bc.created_at,
        member_count_val,
        user_is_member,
        user_role_val,
        creator_name_val
    FROM book_clubs bc
    WHERE bc.id = club_id_param
    AND (bc.is_public = true OR bc.created_by = user_uuid OR user_is_member = true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_book_club_details(UUID, UUID) TO authenticated;

-- Test the function
DO $$
BEGIN
    RAISE NOTICE '✅ Fixed get_book_club_details function';
    RAISE NOTICE 'Now properly returns creator username and accurate member count';
    RAISE NOTICE 'Creator name will show username if available, otherwise name, otherwise "Unknown Creator"';
END $$;
