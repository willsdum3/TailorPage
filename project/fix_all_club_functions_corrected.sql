-- Fix all book club functions with correct column references
-- This fixes the joined_at vs created_at column issue

-- Fix get_book_club_details function
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
    
    -- If user not found, return empty result
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
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
        COALESCE(cm.member_count, 0) as member_count,
        CASE WHEN cm.is_member THEN true ELSE false END as is_member,
        COALESCE(cm.role, 'non-member') as user_role,
        COALESCE(creator.name, 'Unknown') as creator_name
    FROM book_clubs bc
    LEFT JOIN (
        SELECT 
            club_id,
            COUNT(*) as member_count,
            bool_or(user_id = user_uuid) as is_member,
            string_agg(
                CASE WHEN user_id = user_uuid THEN role ELSE NULL END, 
                ','
            ) as role
        FROM club_memberships 
        GROUP BY club_id
    ) cm ON bc.id = cm.club_id
    LEFT JOIN users creator ON bc.created_by = creator.id
    WHERE bc.id = get_book_club_details.club_id
    AND (bc.is_public = true OR bc.created_by = user_uuid OR cm.is_member = true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix get_book_club_members function
DROP FUNCTION IF EXISTS get_book_club_members(UUID, UUID);

CREATE OR REPLACE FUNCTION get_book_club_members(
    auth_user_id UUID,
    club_id UUID
)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    name TEXT,
    avatar_url TEXT,
    role TEXT,
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_uuid UUID;
    is_member BOOLEAN;
BEGIN
    -- Get user UUID from auth_user_id
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_book_club_members.auth_user_id;
    
    -- If user not found, return empty result
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Check if user is a member of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = get_book_club_members.club_id 
        AND user_id = user_uuid
    ) INTO is_member;
    
    -- Only return members if user is a member or club is public
    IF is_member OR EXISTS(
        SELECT 1 FROM book_clubs 
        WHERE id = get_book_club_members.club_id 
        AND is_public = true
    ) THEN
        RETURN QUERY
        SELECT 
            u.id as user_id,
            u.username,
            u.name,
            u.avatar_url,
            cm.role,
            cm.joined_at  -- Use joined_at instead of created_at
        FROM club_memberships cm
        JOIN users u ON cm.user_id = u.id
        WHERE cm.club_id = get_book_club_members.club_id
        ORDER BY 
            CASE WHEN cm.role = 'admin' THEN 1 ELSE 2 END,
            cm.joined_at ASC;  -- Use joined_at instead of created_at
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_book_club_details(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_book_club_members(UUID, UUID) TO authenticated;
