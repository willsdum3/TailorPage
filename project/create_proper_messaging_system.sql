-- Create a proper messaging system that actually stores and retrieves messages
-- This will replace the placeholder functions with real message storage

-- =====================================================
-- DROP EXISTING FUNCTIONS
-- =====================================================

DROP FUNCTION IF EXISTS get_friend_messages(UUID, UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS send_friend_message(UUID, UUID, TEXT);

-- =====================================================
-- GET FRIEND MESSAGES (REAL IMPLEMENTATION)
-- =====================================================

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

-- =====================================================
-- SEND FRIEND MESSAGE (REAL IMPLEMENTATION)
-- =====================================================

CREATE OR REPLACE FUNCTION send_friend_message(
    p_auth_user_id UUID,
    p_friend_id UUID,
    p_content TEXT
) RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_message_id UUID;
    v_conversation_id UUID;
    v_user_name TEXT;
    v_user_username TEXT;
    v_user_avatar_url TEXT;
    v_result JSONB;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT users.id, users.name, users.username, users.avatar_url 
    INTO v_user_id, v_user_name, v_user_username, v_user_avatar_url
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Create a consistent conversation ID based on the two user IDs
    v_conversation_id := md5(LEAST(v_user_id, p_friend_id)::text || GREATEST(v_user_id, p_friend_id)::text)::uuid;
    
    -- Generate a message ID
    v_message_id := gen_random_uuid();
    
    -- Insert the message into the database
    INSERT INTO friend_messages (
        id,
        conversation_id,
        sender_id,
        content,
        message_type,
        book_recommendation,
        created_at,
        is_edited
    ) VALUES (
        v_message_id,
        v_conversation_id,
        v_user_id,
        p_content,
        'text',
        NULL,
        NOW(),
        false
    );
    
    -- Return success response with the message data
    v_result := jsonb_build_object(
        'success', true,
        'message', jsonb_build_object(
            'id', v_message_id,
            'conversationId', v_conversation_id,
            'senderId', v_user_id,
            'senderName', v_user_name,
            'senderUsername', v_user_username,
            'senderImageUrl', v_user_avatar_url,
            'content', p_content,
            'messageType', 'text',
            'bookRecommendation', NULL,
            'createdAt', NOW(),
            'isEdited', false
        )
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TEST THE FUNCTIONS
-- =====================================================

-- Test message sending (replace with actual user IDs)
-- SELECT send_friend_message(
--     'your-auth-user-id-here'::UUID,
--     'friend-user-id-here'::UUID,
--     'Hello! This is a test message.'
-- );

-- Test message retrieval (replace with actual conversation ID)
-- SELECT * FROM get_friend_messages(
--     'your-auth-user-id-here'::UUID,
--     'conversation-id-here'::UUID,
--     10,
--     0
-- );
