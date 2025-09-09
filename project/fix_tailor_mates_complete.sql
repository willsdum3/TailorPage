-- Complete fix for all Tailor Mates functions
-- This addresses both creation and retrieval issues

-- First, let's fix the get_book_clubs function completely
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
    -- Get user UUID from auth_user_id
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_book_clubs.auth_user_id;
    
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
        COALESCE(cm.role, 'non-member') as user_role
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
    WHERE bc.is_public = true OR bc.created_by = user_uuid OR cm.is_member = true
    ORDER BY bc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix get_discussions function with explicit column references
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
    -- Get user UUID from auth_user_id
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_discussions.auth_user_id;
    
    -- If user not found, return empty result
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
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
        CASE WHEN dp.is_participant THEN true ELSE false END as is_participant,
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
            bool_or(user_id = user_uuid) as is_participant
        FROM discussion_participants 
        GROUP BY discussion_id
    ) dp ON d.id = dp.discussion_id
    ORDER BY COALESCE(dm.last_message_at, d.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix create_book_club function to ensure it works properly
CREATE OR REPLACE FUNCTION create_book_club(
    auth_user_id UUID,
    club_name TEXT,
    club_description TEXT,
    current_book_title TEXT DEFAULT NULL,
    current_book_author TEXT DEFAULT NULL,
    max_members INTEGER DEFAULT 10,
    is_public BOOLEAN DEFAULT true,
    target_personality_traits TEXT[] DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    meeting_info TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    club_id UUID;
BEGIN
    -- Get user UUID from auth_user_id
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = create_book_club.auth_user_id;
    
    -- If user not found, raise error
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Create the book club
    INSERT INTO book_clubs (
        name, description, current_book_title, current_book_author,
        max_members, is_public, target_personality_traits, tags, meeting_info, created_by
    ) VALUES (
        club_name, club_description, current_book_title, current_book_author,
        max_members, is_public, target_personality_traits, tags, meeting_info, user_uuid
    ) RETURNING id INTO club_id;
    
    -- Add creator as a member with 'admin' role
    INSERT INTO club_memberships (club_id, user_id, role)
    VALUES (club_id, user_uuid, 'admin');
    
    RETURN club_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix create_discussion function
CREATE OR REPLACE FUNCTION create_discussion(
    auth_user_id UUID,
    discussion_title TEXT,
    discussion_content TEXT,
    book_title TEXT DEFAULT NULL,
    book_author TEXT DEFAULT NULL,
    discussion_tags TEXT[] DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    discussion_id UUID;
BEGIN
    -- Get user UUID from auth_user_id
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = create_discussion.auth_user_id;
    
    -- If user not found, raise error
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Create the discussion
    INSERT INTO discussions (
        title, content, book_title, book_author, tags, created_by
    ) VALUES (
        discussion_title, discussion_content, book_title, book_author, discussion_tags, user_uuid
    ) RETURNING id INTO discussion_id;
    
    -- Add creator as a participant
    INSERT INTO discussion_participants (discussion_id, user_id)
    VALUES (discussion_id, user_uuid);
    
    RETURN discussion_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_book_clubs(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_discussions(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_book_club(UUID, TEXT, TEXT, TEXT, TEXT, INTEGER, BOOLEAN, TEXT[], TEXT[], TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_discussion(UUID, TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;
