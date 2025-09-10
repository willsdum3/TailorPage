-- Simple, working version of book club functions
-- This avoids complex joins and focuses on basic functionality

-- Drop existing functions first
DROP FUNCTION IF EXISTS get_book_club_details(UUID, UUID);
DROP FUNCTION IF EXISTS get_book_club_members(UUID, UUID);
DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS get_book_club_messages(UUID, UUID);

-- Simple get_book_club_details function
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
    club_exists BOOLEAN;
    user_is_member BOOLEAN;
    user_role_val TEXT;
    member_count_val BIGINT;
    creator_name_val TEXT;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_book_club_details.auth_user_id;
    
    -- Check if club exists
    SELECT EXISTS(SELECT 1 FROM book_clubs WHERE id = get_book_club_details.club_id) INTO club_exists;
    
    IF NOT club_exists OR user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Check if user is member
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = get_book_club_details.club_id 
        AND user_id = user_uuid
    ) INTO user_is_member;
    
    -- Get user role
    SELECT role INTO user_role_val
    FROM club_memberships 
    WHERE club_id = get_book_club_details.club_id 
    AND user_id = user_uuid;
    
    -- Get member count
    SELECT COUNT(*) INTO member_count_val
    FROM club_memberships 
    WHERE club_id = get_book_club_details.club_id;
    
    -- Get creator name
    SELECT u.name INTO creator_name_val
    FROM book_clubs bc
    JOIN users u ON bc.created_by = u.id
    WHERE bc.id = get_book_club_details.club_id;
    
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
        COALESCE(user_role_val, 'non-member'),
        COALESCE(creator_name_val, 'Unknown')
    FROM book_clubs bc
    WHERE bc.id = get_book_club_details.club_id
    AND (bc.is_public = true OR bc.created_by = user_uuid OR user_is_member = true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Simple get_book_club_members function
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
    is_public BOOLEAN;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_book_club_members.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Check if user is member
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = get_book_club_members.club_id 
        AND user_id = user_uuid
    ) INTO is_member;
    
    -- Check if club is public
    SELECT is_public INTO is_public
    FROM book_clubs 
    WHERE id = get_book_club_members.club_id;
    
    -- Only return if user is member or club is public
    IF is_member OR is_public THEN
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
        WHERE cm.club_id = get_book_club_members.club_id
        ORDER BY 
            CASE WHEN cm.role = 'admin' THEN 1 ELSE 2 END,
            cm.joined_at ASC;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Simple add_book_club_message function
CREATE OR REPLACE FUNCTION add_book_club_message(
    auth_user_id UUID,
    club_id UUID,
    content TEXT
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
    is_member BOOLEAN;
    new_message_id UUID;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = add_book_club_message.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Check if user is member
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = add_book_club_message.club_id 
        AND user_id = user_uuid
    ) INTO is_member;
    
    IF NOT is_member THEN
        RETURN;
    END IF;
    
    -- Insert message
    INSERT INTO book_club_messages (club_id, user_id, content)
    VALUES (add_book_club_message.club_id, user_uuid, add_book_club_message.content)
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

-- Simple get_book_club_messages function
CREATE OR REPLACE FUNCTION get_book_club_messages(
    auth_user_id UUID,
    club_id UUID
)
RETURNS TABLE (
    id UUID,
    club_id UUID,
    user_id UUID,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    username TEXT,
    name TEXT
) AS $$
DECLARE
    user_uuid UUID;
    is_member BOOLEAN;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_book_club_messages.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Check if user is member
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = get_book_club_messages.club_id 
        AND user_id = user_uuid
    ) INTO is_member;
    
    IF NOT is_member THEN
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
        u.name
    FROM book_club_messages bcm
    JOIN users u ON bcm.user_id = u.id
    WHERE bcm.club_id = get_book_club_messages.club_id
    ORDER BY bcm.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_book_club_details(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_book_club_members(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION add_book_club_message(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_book_club_messages(UUID, UUID) TO authenticated;
