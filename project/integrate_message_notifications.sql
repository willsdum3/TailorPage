-- Integrate notification calls into existing message functions
-- This script updates the existing message functions to create notifications

-- 1. Update add_book_club_message function to create notifications
DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION add_book_club_message(
    auth_user_id UUID,
    club_id_param UUID,
    message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
    v_sender_name TEXT;
    v_club_name TEXT;
    v_member_record RECORD;
    v_notification_count INTEGER := 0;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users
    WHERE auth_user_id = auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Insert the message
    INSERT INTO book_club_messages (club_id, user_id, content, created_at)
    VALUES (club_id_param, user_internal_id, message_content, NOW())
    RETURNING id INTO message_id;
    
    -- Get sender name and club name for notifications
    SELECT name INTO v_sender_name FROM users WHERE id = user_internal_id;
    SELECT name INTO v_club_name FROM book_clubs WHERE id = club_id_param;
    
    -- Create notifications for all members except the sender
    FOR v_member_record IN 
        SELECT user_id 
        FROM club_memberships 
        WHERE club_id = club_id_param 
        AND user_id != user_internal_id
    LOOP
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
        VALUES (
            v_member_record.user_id,
            'club_message',
            'New Message in ' || v_club_name,
            v_sender_name || ': ' || LEFT(message_content, 100) || CASE WHEN LENGTH(message_content) > 100 THEN '...' ELSE '' END,
            club_id_param,
            v_club_name
        );
        v_notification_count := v_notification_count + 1;
    END LOOP;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Update add_discussion_message function to create notifications
DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION add_discussion_message(
    auth_user_id UUID,
    discussion_id_param UUID,
    message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
    v_sender_name TEXT;
    v_discussion_title TEXT;
    v_participant_record RECORD;
    v_notification_count INTEGER := 0;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users
    WHERE auth_user_id = auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Insert the message
    INSERT INTO discussion_messages (discussion_id, user_id, content, created_at)
    VALUES (discussion_id_param, user_internal_id, message_content, NOW())
    RETURNING id INTO message_id;
    
    -- Get sender name and discussion title for notifications
    SELECT name INTO v_sender_name FROM users WHERE id = user_internal_id;
    SELECT title INTO v_discussion_title FROM discussions WHERE id = discussion_id_param;
    
    -- Create notifications for all participants except the sender
    FOR v_participant_record IN 
        SELECT user_id 
        FROM discussion_participants 
        WHERE discussion_id = discussion_id_param 
        AND user_id != user_internal_id
    LOOP
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
        VALUES (
            v_participant_record.user_id,
            'discussion_message',
            'New Message in ' || v_discussion_title,
            v_sender_name || ': ' || LEFT(message_content, 100) || CASE WHEN LENGTH(message_content) > 100 THEN '...' ELSE '' END,
            discussion_id_param,
            v_discussion_title
        );
        v_notification_count := v_notification_count + 1;
    END LOOP;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Update send_friend_message function to create notifications
DROP FUNCTION IF EXISTS send_friend_message(UUID, TEXT, TEXT);
CREATE OR REPLACE FUNCTION send_friend_message(
    auth_user_id UUID,
    friend_id_param TEXT,
    message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    sender_internal_id UUID;
    friend_internal_id UUID;
    conversation_id UUID;
    message_id UUID;
    v_sender_name TEXT;
    v_recipient_id UUID;
BEGIN
    -- Get sender's internal ID
    SELECT id INTO sender_internal_id
    FROM users
    WHERE auth_user_id = auth_user_id;
    
    IF sender_internal_id IS NULL THEN
        RAISE EXCEPTION 'Sender not found';
    END IF;
    
    -- Get friend's internal ID (try by internal ID first, then by username)
    SELECT id INTO friend_internal_id
    FROM users
    WHERE id = friend_id_param::UUID;
    
    IF friend_internal_id IS NULL THEN
        SELECT id INTO friend_internal_id
        FROM users
        WHERE username = friend_id_param;
    END IF;
    
    IF friend_internal_id IS NULL THEN
        RAISE EXCEPTION 'Friend not found';
    END IF;
    
    -- Get or create conversation
    SELECT id INTO conversation_id
    FROM friend_conversations
    WHERE (user1_id = sender_internal_id AND user2_id = friend_internal_id)
    OR (user1_id = friend_internal_id AND user2_id = sender_internal_id);
    
    IF conversation_id IS NULL THEN
        -- Create new conversation
        INSERT INTO friend_conversations (user1_id, user2_id, created_at)
        VALUES (LEAST(sender_internal_id, friend_internal_id), GREATEST(sender_internal_id, friend_internal_id), NOW())
        RETURNING id INTO conversation_id;
    END IF;
    
    -- Insert the message
    INSERT INTO friend_messages (conversation_id, sender_id, content, created_at)
    VALUES (conversation_id, sender_internal_id, message_content, NOW())
    RETURNING id INTO message_id;
    
    -- Get sender name for notification
    SELECT name INTO v_sender_name FROM users WHERE id = sender_internal_id;
    
    -- Get recipient ID from conversation
    SELECT CASE 
        WHEN user1_id = sender_internal_id THEN user2_id 
        ELSE user1_id 
    END INTO v_recipient_id
    FROM friend_conversations 
    WHERE id = conversation_id;
    
    -- Create notification for the recipient
    IF v_recipient_id IS NOT NULL THEN
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
        VALUES (
            v_recipient_id,
            'friend_message',
            'New Message from ' || v_sender_name,
            LEFT(message_content, 100) || CASE WHEN LENGTH(message_content) > 100 THEN '...' ELSE '' END,
            conversation_id,
            v_sender_name
        );
    END IF;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the functions
SELECT 
    'Message Functions Updated' as status,
    'add_book_club_message, add_discussion_message, send_friend_message now create notifications' as message;
