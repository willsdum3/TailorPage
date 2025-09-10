-- Fix parameter errors in book club functions
-- This addresses the specific parameter mismatches causing 400 errors

-- Drop existing functions first
DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS get_book_club_messages(UUID, UUID);

-- Fix add_book_club_message function (parameter name issue)
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
    -- Get user UUID from auth_user_id
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = add_book_club_message.auth_user_id;
    
    -- If user not found, return empty result
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Check if user is a member of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = add_book_club_message.club_id 
        AND user_id = user_uuid
    ) INTO is_member;
    
    -- If user is not a member, return empty result
    IF NOT is_member THEN
        RETURN;
    END IF;
    
    -- Insert the message (using correct parameter name 'content')
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

-- Fix get_book_club_messages function (remove non-existent parameters)
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
    name TEXT,
    avatar_url TEXT
) AS $$
DECLARE
    user_uuid UUID;
    is_member BOOLEAN;
BEGIN
    -- Get user UUID from auth_user_id
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_book_club_messages.auth_user_id;
    
    -- If user not found, return empty result
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Check if user is a member of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = get_book_club_messages.club_id 
        AND user_id = user_uuid
    ) INTO is_member;
    
    -- Only return messages if user is a member
    IF is_member THEN
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
        WHERE bcm.club_id = get_book_club_messages.club_id
        ORDER BY bcm.created_at ASC;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION add_book_club_message(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_book_club_messages(UUID, UUID) TO authenticated;
