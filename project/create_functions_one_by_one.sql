-- Create book club functions one by one to ensure they work
-- This approach creates each function individually

-- Step 1: Create get_book_club_details function
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
BEGIN
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
        1::BIGINT as member_count,
        true as is_member,
        'member'::TEXT as user_role,
        'Creator'::TEXT as creator_name
    FROM book_clubs bc
    WHERE bc.id = get_book_club_details.club_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permission for get_book_club_details
GRANT EXECUTE ON FUNCTION get_book_club_details(UUID, UUID) TO authenticated;
