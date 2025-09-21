-- Create Friends messaging functions
-- This script creates all functions needed for the Friends messaging system

-- =====================================================
-- FRIEND CONVERSATIONS FUNCTIONS
-- =====================================================

-- Get or create conversation between two users
CREATE OR REPLACE FUNCTION get_or_create_conversation(
    p_auth_user_id UUID,
    p_friend_id UUID
) RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
    v_conversation_id UUID;
    v_user1_id UUID;
    v_user2_id UUID;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Ensure consistent ordering for conversation participants
    v_user1_id := LEAST(v_user_id, p_friend_id);
    v_user2_id := GREATEST(v_user_id, p_friend_id);
    
    -- Try to find existing conversation
    SELECT id INTO v_conversation_id
    FROM friend_conversations
    WHERE user1_id = v_user1_id AND user2_id = v_user2_id;
    
    -- Create new conversation if it doesn't exist
    IF v_conversation_id IS NULL THEN
        INSERT INTO friend_conversations (user1_id, user2_id)
        VALUES (v_user1_id, v_user2_id)
        RETURNING id INTO v_conversation_id;
    END IF;
    
    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get friend conversations for a user
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
    unread_count BIGINT,
    is_online BOOLEAN
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
    SELECT 
        fc.id,
        CASE 
            WHEN fc.user1_id = v_user_id THEN fc.user2_id 
            ELSE fc.user1_id 
        END as friend_id,
        CASE 
            WHEN fc.user1_id = v_user_id THEN u2.name 
            ELSE u1.name 
        END as friend_name,
        CASE 
            WHEN fc.user1_id = v_user_id THEN u2.username 
            ELSE u1.username 
        END as friend_username,
        CASE 
            WHEN fc.user1_id = v_user_id THEN u2.avatar_url 
            ELSE u1.avatar_url 
        END as friend_image_url,
        lm.content as last_message,
        lm.created_at as last_message_at,
        COALESCE(unread.unread_count, 0) as unread_count,
        FALSE as is_online -- TODO: Implement online status
    FROM friend_conversations fc
    JOIN users u1 ON fc.user1_id = u1.id
    JOIN users u2 ON fc.user2_id = u2.id
    LEFT JOIN LATERAL (
        SELECT content, created_at
        FROM friend_messages fm
        WHERE fm.conversation_id = fc.id
        ORDER BY fm.created_at DESC
        LIMIT 1
    ) lm ON true
    LEFT JOIN LATERAL (
        SELECT COUNT(*) as unread_count
        FROM friend_messages fm
        WHERE fm.conversation_id = fc.id
        AND fm.sender_id != v_user_id
        AND fm.is_read = FALSE
    ) unread ON true
    WHERE fc.user1_id = v_user_id OR fc.user2_id = v_user_id
    ORDER BY COALESCE(lm.created_at, fc.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FRIEND MESSAGING FUNCTIONS
-- =====================================================

-- Send a text message
CREATE OR REPLACE FUNCTION send_friend_message(
    p_auth_user_id UUID,
    p_friend_id UUID,
    p_content TEXT
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_conversation_id UUID;
    v_message_id UUID;
    v_message_record RECORD;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if users are friends
    IF NOT EXISTS (
        SELECT 1 FROM friend_requests
        WHERE ((requester_id = v_user_id AND target_id = p_friend_id) OR 
               (requester_id = p_friend_id AND target_id = v_user_id))
        AND status = 'accepted'
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Users are not friends');
    END IF;
    
    -- Get or create conversation
    v_conversation_id := get_or_create_conversation(p_auth_user_id, p_friend_id);
    
    -- Insert message
    INSERT INTO friend_messages (conversation_id, sender_id, content, message_type)
    VALUES (v_conversation_id, v_user_id, p_content, 'text')
    RETURNING id INTO v_message_id;
    
    -- Get message details for response
    SELECT 
        fm.id,
        fm.content,
        fm.created_at,
        fm.sender_id,
        u.name as sender_name,
        u.username as sender_username,
        u.avatar_url as sender_image_url,
        fm.is_read
    INTO v_message_record
    FROM friend_messages fm
    JOIN users u ON fm.sender_id = u.id
    WHERE fm.id = v_message_id;
    
    -- Create notification for recipient
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    SELECT 
        p_friend_id,
        'friend_message',
        'New Message',
        v_message_record.sender_name || ' sent you a message',
        v_user_id,
        v_message_record.sender_name;
    
    RETURN json_build_object(
        'success', true,
        'message', json_build_object(
            'id', v_message_record.id,
            'conversationId', v_conversation_id,
            'senderId', v_message_record.sender_id,
            'senderName', v_message_record.sender_name,
            'senderUsername', v_message_record.sender_username,
            'senderImageUrl', v_message_record.sender_image_url,
            'content', v_message_record.content,
            'messageType', 'text',
            'createdAt', v_message_record.created_at,
            'isRead', v_message_record.is_read
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Send a book recommendation
CREATE OR REPLACE FUNCTION send_book_recommendation(
    p_auth_user_id UUID,
    p_friend_id UUID,
    p_book_title TEXT,
    p_book_author TEXT,
    p_description TEXT DEFAULT NULL,
    p_amazon_url TEXT DEFAULT NULL,
    p_cover_image_url TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_conversation_id UUID;
    v_message_id UUID;
    v_book_data JSONB;
    v_message_record RECORD;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if users are friends
    IF NOT EXISTS (
        SELECT 1 FROM friend_requests
        WHERE ((requester_id = v_user_id AND target_id = p_friend_id) OR 
               (requester_id = p_friend_id AND target_id = v_user_id))
        AND status = 'accepted'
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Users are not friends');
    END IF;
    
    -- Get or create conversation
    v_conversation_id := get_or_create_conversation(p_auth_user_id, p_friend_id);
    
    -- Prepare book recommendation data
    v_book_data := json_build_object(
        'title', p_book_title,
        'author', p_book_author,
        'description', p_description,
        'amazonUrl', p_amazon_url,
        'coverImageUrl', p_cover_image_url
    );
    
    -- Insert message
    INSERT INTO friend_messages (
        conversation_id, sender_id, content, message_type, book_recommendation
    )
    VALUES (
        v_conversation_id, v_user_id, 
        'Recommended: ' || p_book_title || ' by ' || p_book_author,
        'book_recommendation', v_book_data
    )
    RETURNING id INTO v_message_id;
    
    -- Get message details for response
    SELECT 
        fm.id,
        fm.content,
        fm.book_recommendation,
        fm.created_at,
        fm.sender_id,
        u.name as sender_name,
        u.username as sender_username,
        u.avatar_url as sender_image_url,
        fm.is_read
    INTO v_message_record
    FROM friend_messages fm
    JOIN users u ON fm.sender_id = u.id
    WHERE fm.id = v_message_id;
    
    -- Create notification for recipient
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    SELECT 
        p_friend_id,
        'friend_message',
        'Book Recommendation',
        v_message_record.sender_name || ' recommended a book: ' || p_book_title,
        v_user_id,
        v_message_record.sender_name;
    
    RETURN json_build_object(
        'success', true,
        'message', json_build_object(
            'id', v_message_record.id,
            'conversationId', v_conversation_id,
            'senderId', v_message_record.sender_id,
            'senderName', v_message_record.sender_name,
            'senderUsername', v_message_record.sender_username,
            'senderImageUrl', v_message_record.sender_image_url,
            'content', v_message_record.content,
            'messageType', 'book_recommendation',
            'bookRecommendation', v_message_record.book_recommendation,
            'createdAt', v_message_record.created_at,
            'isRead', v_message_record.is_read
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get messages for a conversation
CREATE OR REPLACE FUNCTION get_friend_messages(
    p_auth_user_id UUID,
    p_conversation_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_messages JSON;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_array();
    END IF;
    
    -- Check if user is part of this conversation
    IF NOT EXISTS (
        SELECT 1 FROM friend_conversations
        WHERE id = p_conversation_id
        AND (user1_id = v_user_id OR user2_id = v_user_id)
    ) THEN
        RETURN json_build_array();
    END IF;
    
    -- Mark messages as read for this user
    UPDATE friend_messages
    SET is_read = TRUE
    WHERE conversation_id = p_conversation_id
    AND sender_id != v_user_id
    AND is_read = FALSE;
    
    -- Get messages
    SELECT json_agg(
        json_build_object(
            'id', fm.id,
            'conversationId', fm.conversation_id,
            'senderId', fm.sender_id,
            'senderName', u.name,
            'senderUsername', u.username,
            'senderImageUrl', u.avatar_url,
            'content', fm.content,
            'messageType', fm.message_type,
            'bookRecommendation', fm.book_recommendation,
            'createdAt', fm.created_at,
            'isRead', fm.is_read
        ) ORDER BY fm.created_at ASC
    ) INTO v_messages
    FROM friend_messages fm
    JOIN users u ON fm.sender_id = u.id
    WHERE fm.conversation_id = p_conversation_id
    ORDER BY fm.created_at DESC
    LIMIT p_limit OFFSET p_offset;
    
    RETURN COALESCE(v_messages, json_build_array());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Test the functions exist
SELECT 
    routine_name as function_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'get_or_create_conversation',
    'get_friend_conversations', 
    'send_friend_message',
    'send_book_recommendation',
    'get_friend_messages'
)
ORDER BY routine_name;
