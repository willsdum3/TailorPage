-- Fix messaging function conflicts by dropping existing functions first

-- 1. Drop existing messaging functions with all possible signatures
DROP FUNCTION IF EXISTS send_friend_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS send_friend_message(UUID, TEXT);
DROP FUNCTION IF EXISTS send_friend_message CASCADE;

DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS add_book_club_message(UUID, TEXT);
DROP FUNCTION IF EXISTS add_book_club_message CASCADE;

DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS add_discussion_message(UUID, TEXT);
DROP FUNCTION IF EXISTS add_discussion_message CASCADE;

-- 2. Create book club messaging function
CREATE OR REPLACE FUNCTION add_book_club_message(
    auth_user_id UUID,
    club_id_param UUID,
    message_text TEXT
)
RETURNS JSON AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
BEGIN
    -- Get the internal user ID
    SELECT id INTO user_internal_id
    FROM users
    WHERE users.auth_user_id = add_book_club_message.auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE user_id = user_internal_id 
        AND club_id = club_id_param
    ) THEN
        RETURN json_build_object('success', false, 'error', 'You are not a member of this club');
    END IF;
    
    -- Insert the message
    INSERT INTO book_club_messages (user_id, club_id, message, created_at)
    VALUES (user_internal_id, club_id_param, message_text, NOW())
    RETURNING id INTO message_id;
    
    -- Create notification for other club members
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        related_id,
        related_name
    )
    SELECT 
        bcm.user_id,
        'club_message',
        'New message in book club',
        (SELECT name FROM users WHERE id = user_internal_id) || ' sent a message',
        club_id_param,
        (SELECT name FROM book_clubs WHERE id = club_id_param)
    FROM book_club_members bcm
    WHERE bcm.club_id = club_id_param
    AND bcm.user_id != user_internal_id;
    
    RETURN json_build_object('success', true, 'message_id', message_id, 'message', 'Message sent successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create discussion messaging function
CREATE OR REPLACE FUNCTION add_discussion_message(
    auth_user_id UUID,
    discussion_id_param UUID,
    message_text TEXT
)
RETURNS JSON AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
BEGIN
    -- Get the internal user ID
    SELECT id INTO user_internal_id
    FROM users
    WHERE users.auth_user_id = add_discussion_message.auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if user is a member of the discussion
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members 
        WHERE user_id = user_internal_id 
        AND discussion_id = discussion_id_param
    ) THEN
        RETURN json_build_object('success', false, 'error', 'You are not a member of this discussion');
    END IF;
    
    -- Insert the message
    INSERT INTO discussion_messages (user_id, discussion_id, message, created_at)
    VALUES (user_internal_id, discussion_id_param, message_text, NOW())
    RETURNING id INTO message_id;
    
    -- Create notification for other discussion members
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        related_id,
        related_name
    )
    SELECT 
        dm.user_id,
        'discussion_message',
        'New message in discussion',
        (SELECT name FROM users WHERE id = user_internal_id) || ' sent a message',
        discussion_id_param,
        (SELECT title FROM discussions WHERE id = discussion_id_param)
    FROM discussion_members dm
    WHERE dm.discussion_id = discussion_id_param
    AND dm.user_id != user_internal_id;
    
    RETURN json_build_object('success', true, 'message_id', message_id, 'message', 'Message sent successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create friend messaging function
CREATE OR REPLACE FUNCTION send_friend_message(
    auth_user_id UUID,
    friend_id_param UUID,
    message_text TEXT
)
RETURNS JSON AS $$
DECLARE
    user_internal_id UUID;
    friend_internal_id UUID;
    conversation_id UUID;
    message_id UUID;
BEGIN
    -- Get the internal user ID
    SELECT id INTO user_internal_id
    FROM users
    WHERE users.auth_user_id = send_friend_message.auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- friend_id_param is already the internal ID from frontend
    friend_internal_id := send_friend_message.friend_id_param;
    
    -- Check if users are friends
    IF NOT EXISTS (
        SELECT 1 FROM friend_connections 
        WHERE (user_id = user_internal_id AND friend_id = friend_internal_id)
        OR (user_id = friend_internal_id AND friend_id = user_internal_id)
        AND status = 'accepted'
    ) THEN
        RETURN json_build_object('success', false, 'error', 'You are not friends with this user');
    END IF;
    
    -- Get or create conversation
    SELECT id INTO conversation_id
    FROM conversations
    WHERE (user1_id = user_internal_id AND user2_id = friend_internal_id)
    OR (user1_id = friend_internal_id AND user2_id = user_internal_id);
    
    IF conversation_id IS NULL THEN
        INSERT INTO conversations (user1_id, user2_id, created_at, updated_at)
        VALUES (user_internal_id, friend_internal_id, NOW(), NOW())
        RETURNING id INTO conversation_id;
    END IF;
    
    -- Insert the message
    INSERT INTO friend_messages (conversation_id, sender_id, message, created_at)
    VALUES (conversation_id, user_internal_id, message_text, NOW())
    RETURNING id INTO message_id;
    
    -- Update conversation timestamp
    UPDATE conversations 
    SET updated_at = NOW()
    WHERE id = conversation_id;
    
    -- Create notification for the friend
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        related_id,
        related_name
    ) VALUES (
        friend_internal_id,
        'friend_message',
        'New message from friend',
        (SELECT name FROM users WHERE id = user_internal_id) || ' sent you a message',
        conversation_id,
        (SELECT name FROM users WHERE id = user_internal_id)
    );
    
    RETURN json_build_object('success', true, 'message_id', message_id, 'conversation_id', conversation_id, 'message', 'Message sent successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Verify all messaging functions were created
SELECT 
    'Messaging Functions Created' as check_type,
    routine_name,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('add_book_club_message', 'add_discussion_message', 'send_friend_message')
ORDER BY routine_name;
