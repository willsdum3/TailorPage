-- Simplified version of get_book_club_details function for debugging
-- This removes complex logic to identify the issue

DROP FUNCTION IF EXISTS get_book_club_details(UUID, UUID);

CREATE OR REPLACE FUNCTION get_book_club_details(
    auth_user_id UUID,
    club_id UUID
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
BEGIN
    -- Get user UUID from auth_user_id
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_book_club_details.auth_user_id;
    
    -- Debug: Log the user lookup
    RAISE NOTICE 'Looking up user with auth_user_id: %', get_book_club_details.auth_user_id;
    RAISE NOTICE 'Found user_uuid: %', user_uuid;
    RAISE NOTICE 'Looking for club_id: %', get_book_club_details.club_id;
    
    -- If user not found, return empty result
    IF user_uuid IS NULL THEN
        RAISE NOTICE 'User not found, returning empty result';
        RETURN;
    END IF;
    
    -- Simple query without complex joins first
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
        0::BIGINT as member_count,  -- Simplified for now
        false as is_member,         -- Simplified for now
        'non-member'::TEXT as user_role,  -- Simplified for now
        'Unknown'::TEXT as creator_name   -- Simplified for now
    FROM book_clubs bc
    WHERE bc.id = get_book_club_details.club_id;
    
    RAISE NOTICE 'Query executed, returning results';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_book_club_details(UUID, UUID) TO authenticated;
