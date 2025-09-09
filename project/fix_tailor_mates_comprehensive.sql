-- Comprehensive fix for Tailor Mates ambiguous column references
-- This fixes all the "column reference 'auth_user_id' is ambiguous" errors

-- First, let's ensure the get_user_id_from_auth function is properly defined
CREATE OR REPLACE FUNCTION get_user_id_from_auth(auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
BEGIN
    SELECT id INTO user_uuid 
    FROM users 
    WHERE users.auth_user_id = get_user_id_from_auth.auth_user_id;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix get_book_clubs function with proper parameter references
CREATE OR REPLACE FUNCTION get_book_clubs(auth_user_id UUID)
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
    user_role TEXT
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get the user UUID from the auth_user_id parameter
    user_uuid := get_user_id_from_auth(get_book_clubs.auth_user_id);
    
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
        CASE WHEN cm.user_id IS NOT NULL THEN true ELSE false END as is_member,
        COALESCE(cm.role, 'non-member') as user_role
    FROM book_clubs bc
    LEFT JOIN (
        SELECT 
            club_id,
            COUNT(*) as member_count,
            MAX(CASE WHEN user_id = user_uuid THEN role ELSE NULL END) as role,
            MAX(CASE WHEN user_id = user_uuid THEN user_id ELSE NULL END) as user_id
        FROM club_memberships 
        GROUP BY club_id
    ) cm ON bc.id = cm.club_id
    WHERE bc.is_public = true OR bc.created_by = user_uuid OR cm.user_id = user_uuid
    ORDER BY bc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix get_discussions function with proper parameter references
CREATE OR REPLACE FUNCTION get_discussions(auth_user_id UUID)
RETURNS TABLE (
    id UUID,
    title TEXT,
    content TEXT,
    book_title TEXT,
    book_author TEXT,
    tags TEXT[],
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    message_count BIGINT,
    participant_count BIGINT,
    is_participant BOOLEAN,
    last_message_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get the user UUID from the auth_user_id parameter
    user_uuid := get_user_id_from_auth(get_discussions.auth_user_id);
    
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        d.content,
        d.book_title,
        d.book_author,
        d.tags,
        d.created_by,
        d.created_at,
        d.updated_at,
        COALESCE(dm.message_count, 0) as message_count,
        COALESCE(dp.participant_count, 0) as participant_count,
        CASE WHEN dp.user_id IS NOT NULL THEN true ELSE false END as is_participant,
        COALESCE(dm.last_message_at, d.created_at) as last_message_at
    FROM discussions d
    LEFT JOIN (
        SELECT 
            discussion_id,
            COUNT(*) as message_count,
            MAX(created_at) as last_message_at
        FROM discussion_messages 
        GROUP BY discussion_id
    ) dm ON d.id = dm.discussion_id
    LEFT JOIN (
        SELECT 
            discussion_id,
            COUNT(*) as participant_count,
            MAX(CASE WHEN user_id = user_uuid THEN user_id ELSE NULL END) as user_id
        FROM discussion_participants 
        GROUP BY discussion_id
    ) dp ON d.id = dp.discussion_id
    ORDER BY COALESCE(dm.last_message_at, d.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_user_id_from_auth(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_book_clubs(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_discussions(UUID) TO authenticated;
