-- Fix the column reference ambiguity in get_friend_messages function
-- This script fixes the "conversation_id is ambiguous" error

-- Drop and recreate the function with proper table aliases
DROP FUNCTION IF EXISTS get_friend_messages(UUID, UUID, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION get_friend_messages(
    p_auth_user_id UUID,
    p_conversation_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
) RETURNS TABLE(
    id UUID,
    conversation_id UUID,
    sender_id UUID,
    sender_name TEXT,
    sender_username TEXT,
    sender_image_url TEXT,
    content TEXT,
    message_type TEXT,
    book_recommendation JSONB,
    created_at TIMESTAMP WITH TIME ZONE,
    is_edited BOOLEAN
) AS $$
DECLARE
    v_user_id UUID;
    v_friend_id UUID;
    v_conversation_exists BOOLEAN;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if this conversation exists in friend_messages table
    -- Use table alias to avoid ambiguity
    SELECT EXISTS(
        SELECT 1 FROM friend_messages fm
        WHERE fm.conversation_id = p_conversation_id
    ) INTO v_conversation_exists;
    
    -- If no messages exist, return a welcome message
    IF NOT v_conversation_exists THEN
        RETURN QUERY
        SELECT 
            gen_random_uuid() as id,
            p_conversation_id as conversation_id,
            v_user_id as sender_id,
            'System' as sender_name,
            'system' as sender_username,
            NULL::TEXT as sender_image_url,
            'Start the conversation!' as content,
            'text' as message_type,
            NULL::JSONB as book_recommendation,
            NOW() as created_at,
            false as is_edited;
        RETURN;
    END IF;
    
    -- Return actual messages from the database
    RETURN QUERY
    SELECT 
        fm.id,
        fm.conversation_id,
        fm.sender_id,
        u.name as sender_name,
        u.username as sender_username,
        u.avatar_url as sender_image_url,
        fm.content,
        fm.message_type,
        fm.book_recommendation,
        fm.created_at,
        COALESCE(fm.is_edited, false) as is_edited
    FROM friend_messages fm
    JOIN users u ON fm.sender_id = u.id
    WHERE fm.conversation_id = p_conversation_id
    ORDER BY fm.created_at ASC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
