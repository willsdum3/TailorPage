-- Final working version of book club functions
-- This ensures all functions are created with correct signatures

-- Drop all existing functions first
DROP FUNCTION IF EXISTS get_book_club_details(UUID, UUID);
DROP FUNCTION IF EXISTS get_book_club_members(UUID, UUID);
DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS get_book_club_messages(UUID, UUID);

-- Create get_book_club_details function
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
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_book_club_details.auth_user_id;
    
    -- If user not found, return empty
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Return basic club info
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

-- Create get_book_club_members function
CREATE OR REPLACE FUNCTION get_book_club_members(
    auth_user_id UUID,
    club_id_param UUID
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
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_book_club_members.auth_user_id;
    
    -- If user not found, return empty
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Return members
    RETURN QUERY
    SELECT 
        u.id as user_id,
        u.username,
        u.name,
        u.avatar_url,
        cm.role,
        cm.joined_at
    FROM club_memberships cm
    JOIN users u ON cm.user_id = u.id
    WHERE cm.club_id = get_book_club_members.club_id_param
    ORDER BY cm.joined_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create add_book_club_message function
CREATE OR REPLACE FUNCTION add_book_club_message(
    auth_user_id UUID,
    club_id_param UUID,
    content_param TEXT
)
RETURNS TABLE (
    id UUID,
    club_id UUID,
    user_id UUID,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_uuid UUID;
    new_message_id UUID;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = add_book_club_message.auth_user_id;
    
    -- If user not found, return empty
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Insert message
    INSERT INTO book_club_messages (club_id, user_id, content)
    VALUES (add_book_club_message.club_id_param, user_uuid, add_book_club_message.content_param)
    RETURNING book_club_messages.id INTO new_message_id;
    
    -- Return the new message
    RETURN QUERY
    SELECT 
        bcm.id,
        bcm.club_id,
        bcm.user_id,
        bcm.content,
        bcm.created_at
    FROM book_club_messages bcm
    WHERE bcm.id = new_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create get_book_club_messages function
CREATE OR REPLACE FUNCTION get_book_club_messages(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID,
    club_id UUID,
    user_id UUID,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    username TEXT,
    name TEXT,
    avatar_url TEXT
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_book_club_messages.auth_user_id;
    
    -- If user not found, return empty
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Return messages
    RETURN QUERY
    SELECT 
        bcm.id,
        bcm.club_id,
        bcm.user_id,
        bcm.content,
        bcm.created_at,
        u.username,
        u.name,
        u.avatar_url
    FROM book_club_messages bcm
    JOIN users u ON bcm.user_id = u.id
    WHERE bcm.club_id = get_book_club_messages.club_id_param
    ORDER BY bcm.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_book_club_details(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_book_club_members(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION add_book_club_message(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_book_club_messages(UUID, UUID) TO authenticated;
