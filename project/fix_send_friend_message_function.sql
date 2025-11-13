-- Fix send_friend_message to use friend_conversations and return structured JSON

DROP FUNCTION IF EXISTS send_friend_message(UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION send_friend_message(
    p_auth_user_id UUID,
    p_friend_id UUID,
    p_content TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_sender_id UUID;
    v_friend_id UUID;
    v_conversation_id UUID;
    v_recipient_id UUID;
    v_sender_name TEXT;
    v_sender_username TEXT;
    v_sender_avatar TEXT;
    v_message_record friend_messages%ROWTYPE;
BEGIN
    -- Basic validation
    IF COALESCE(TRIM(p_content), '') = '' THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Message cannot be empty');
    END IF;

    -- Resolve sender internal ID
    SELECT id, username, avatar_url, COALESCE(name, username)
    INTO v_sender_id, v_sender_username, v_sender_avatar, v_sender_name
    FROM users
    WHERE auth_user_id = p_auth_user_id;

    IF v_sender_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Sender not found');
    END IF;

    v_friend_id := p_friend_id;

    -- Check if sender is blocked by recipient
    IF EXISTS (
        SELECT 1
        FROM user_blocks ub
        WHERE ub.blocker_id = v_friend_id
          AND ub.blocked_id = v_sender_id
    ) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'You cannot send messages to this user. You have been blocked.');
    END IF;

    -- Check if sender has blocked the recipient
    IF EXISTS (
        SELECT 1
        FROM user_blocks ub
        WHERE ub.blocker_id = v_sender_id
          AND ub.blocked_id = v_friend_id
    ) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'You cannot send messages to this user. You have blocked them.');
    END IF;

    -- Ensure they are friends (accepted status in either direction)
    IF NOT EXISTS (
        SELECT 1
        FROM friend_connections
        WHERE ((user_id = v_sender_id AND friend_id = v_friend_id)
            OR (user_id = v_friend_id AND friend_id = v_sender_id))
          AND status = 'accepted'
    ) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'You are not friends with this user');
    END IF;

    -- Find existing conversation or create one
    SELECT id INTO v_conversation_id
    FROM friend_conversations
    WHERE (user1_id = v_sender_id AND user2_id = v_friend_id)
       OR (user1_id = v_friend_id AND user2_id = v_sender_id);

    IF v_conversation_id IS NULL THEN
        INSERT INTO friend_conversations (user1_id, user2_id, created_at)
        VALUES (LEAST(v_sender_id, v_friend_id), GREATEST(v_sender_id, v_friend_id), NOW())
        RETURNING id INTO v_conversation_id;
    END IF;

    -- Store the message
    INSERT INTO friend_messages (conversation_id, sender_id, content, message_type, created_at)
    VALUES (v_conversation_id, v_sender_id, p_content, 'text', NOW())
    RETURNING * INTO v_message_record;

    -- Determine the recipient for notifications
    SELECT CASE WHEN user1_id = v_sender_id THEN user2_id ELSE user1_id END
    INTO v_recipient_id
    FROM friend_conversations
    WHERE id = v_conversation_id;

    -- Best-effort notification
    BEGIN
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name, created_at)
        VALUES (
            v_recipient_id,
            'friend_message',
            'New message from ' || v_sender_name,
            LEFT(p_content, 120),
            v_conversation_id,
            v_sender_name,
            NOW()
        );
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', jsonb_build_object(
            'id', v_message_record.id,
            'conversationId', v_message_record.conversation_id,
            'senderId', v_message_record.sender_id,
            'senderName', v_sender_name,
            'senderUsername', v_sender_username,
            'senderImageUrl', v_sender_avatar,
            'content', v_message_record.content,
            'messageType', v_message_record.message_type,
            'bookRecommendation', v_message_record.book_recommendation,
            'createdAt', v_message_record.created_at,
            'isEdited', COALESCE(v_message_record.is_edited, FALSE),
            'isRead', TRUE
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;
