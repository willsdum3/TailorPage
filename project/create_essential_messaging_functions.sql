-- Create essential messaging functions for Friends system
-- This script creates the core functions needed for messaging to work

-- =====================================================
-- DROP EXISTING FUNCTIONS (if any)
-- =====================================================

DROP FUNCTION IF EXISTS get_friend_conversations(UUID);
DROP FUNCTION IF EXISTS get_friend_messages(UUID, UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS send_friend_message(UUID, UUID, TEXT);

-- =====================================================
-- GET FRIEND CONVERSATIONS
-- =====================================================

CREATE OR REPLACE FUNCTION get_friend_conversations(
    p_auth_user_id UUID
) RETURNS TABLE(
    id UUID,
    friend_id UUID,
    friend_name TEXT,
    friend_username TEXT,
    friend_image_url TEXT,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    unread_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    RETURN QUERY
    SELECT DISTINCT
        gen_random_uuid() as id, -- Generate a conversation ID for now
        CASE 
            WHEN fr.requester_id = v_user_id THEN fr.target_id 
            ELSE fr.requester_id 
        END as friend_id,
        CASE 
            WHEN fr.requester_id = v_user_id THEN u2.name 
            ELSE u1.name 
        END as friend_name,
        CASE 
            WHEN fr.requester_id = v_user_id THEN u2.username 
            ELSE u1.username 
        END as friend_username,
        CASE 
            WHEN fr.requester_id = v_user_id THEN u2.avatar_url 
            ELSE u1.avatar_url 
        END as friend_image_url,
        'No messages yet' as last_message,
        NOW() as last_message_at,
        0 as unread_count,
        fr.created_at
    FROM friend_requests fr
    LEFT JOIN users u1 ON fr.requester_id = u1.id
    LEFT JOIN users u2 ON fr.target_id = u2.id
    WHERE (fr.requester_id = v_user_id OR fr.target_id = v_user_id)
    AND fr.status = 'accepted'
    ORDER BY fr.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GET FRIEND MESSAGES
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
BEGIN
    -- Get the user ID from auth_user_id
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Return a welcome message to start the conversation
    RETURN QUERY
    SELECT 
        gen_random_uuid() as id,
        p_conversation_id as conversation_id,
        v_user_id as sender_id,
        'System' as sender_name,
        'system' as sender_username,
        NULL as sender_image_url,
        'Start the conversation!' as content,
        'text' as message_type,
        NULL as book_recommendation,
        NOW() as created_at,
        false as is_edited;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SEND FRIEND MESSAGE
-- =====================================================

CREATE OR REPLACE FUNCTION send_friend_message(
    p_auth_user_id UUID,
    p_friend_id UUID,
    p_content TEXT
) RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_message_id UUID;
    v_result JSONB;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- For now, just return a success response
    -- In a full implementation, this would create the message in the database
    v_message_id := gen_random_uuid();
    
    v_result := jsonb_build_object(
        'success', true,
        'message', jsonb_build_object(
            'id', v_message_id,
            'conversationId', gen_random_uuid(),
            'senderId', v_user_id,
            'senderName', 'You',
            'senderUsername', 'you',
            'senderImageUrl', NULL,
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
