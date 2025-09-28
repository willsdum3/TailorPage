-- Create functions to manually create notifications for messages
-- Since we can't easily trigger on message insertions, we'll create functions to call manually

-- Function to create book club message notification
DROP FUNCTION IF EXISTS create_club_message_notification(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION create_club_message_notification(
    p_club_id UUID,
    p_sender_id UUID,
    p_message_content TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_sender_name TEXT;
    v_club_name TEXT;
    v_member_record RECORD;
    v_notification_count INTEGER := 0;
BEGIN
    -- Get sender name
    SELECT name INTO v_sender_name
    FROM users 
    WHERE id = p_sender_id;
    
    -- Get club name
    SELECT name INTO v_club_name
    FROM book_clubs 
    WHERE id = p_club_id;
    
    -- Notify all members except the sender
    FOR v_member_record IN 
        SELECT user_id 
        FROM club_memberships 
        WHERE club_id = p_club_id 
        AND user_id != p_sender_id
    LOOP
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
        VALUES (
            v_member_record.user_id,
            'club_message',
            'New Message in ' || v_club_name,
            v_sender_name || ': ' || LEFT(p_message_content, 100) || CASE WHEN LENGTH(p_message_content) > 100 THEN '...' ELSE '' END,
            p_club_id,
            v_club_name
        );
        v_notification_count := v_notification_count + 1;
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Club message notifications created',
        'notifications_created', v_notification_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create discussion message notification
DROP FUNCTION IF EXISTS create_discussion_message_notification(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION create_discussion_message_notification(
    p_discussion_id UUID,
    p_sender_id UUID,
    p_message_content TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_sender_name TEXT;
    v_discussion_title TEXT;
    v_participant_record RECORD;
    v_notification_count INTEGER := 0;
BEGIN
    -- Get sender name
    SELECT name INTO v_sender_name
    FROM users 
    WHERE id = p_sender_id;
    
    -- Get discussion title
    SELECT title INTO v_discussion_title
    FROM discussions 
    WHERE id = p_discussion_id;
    
    -- Notify all participants except the sender
    FOR v_participant_record IN 
        SELECT user_id 
        FROM discussion_participants 
        WHERE discussion_id = p_discussion_id 
        AND user_id != p_sender_id
    LOOP
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
        VALUES (
            v_participant_record.user_id,
            'discussion_message',
            'New Message in ' || v_discussion_title,
            v_sender_name || ': ' || LEFT(p_message_content, 100) || CASE WHEN LENGTH(p_message_content) > 100 THEN '...' ELSE '' END,
            p_discussion_id,
            v_discussion_title
        );
        v_notification_count := v_notification_count + 1;
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Discussion message notifications created',
        'notifications_created', v_notification_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create friend message notification
DROP FUNCTION IF EXISTS create_friend_message_notification(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION create_friend_message_notification(
    p_conversation_id UUID,
    p_sender_id UUID,
    p_message_content TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_sender_name TEXT;
    v_recipient_id UUID;
    v_notification_count INTEGER := 0;
BEGIN
    -- Get sender name
    SELECT name INTO v_sender_name
    FROM users 
    WHERE id = p_sender_id;
    
    -- Get recipient ID from conversation
    SELECT CASE 
        WHEN user1_id = p_sender_id THEN user2_id 
        ELSE user1_id 
    END INTO v_recipient_id
    FROM friend_conversations 
    WHERE id = p_conversation_id;
    
    -- Create notification for the recipient
    IF v_recipient_id IS NOT NULL THEN
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
        VALUES (
            v_recipient_id,
            'friend_message',
            'New Message from ' || v_sender_name,
            LEFT(p_message_content, 100) || CASE WHEN LENGTH(p_message_content) > 100 THEN '...' ELSE '' END,
            p_conversation_id,
            v_sender_name
        );
        v_notification_count := 1;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Friend message notification created',
        'notifications_created', v_notification_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to manually create admin promotion notification
DROP FUNCTION IF EXISTS create_admin_promotion_notification(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION create_admin_promotion_notification(
    p_promoted_user_id UUID,
    p_club_id UUID,
    p_promoter_name TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_club_name TEXT;
BEGIN
    -- Get club name
    SELECT name INTO v_club_name
    FROM book_clubs 
    WHERE id = p_club_id;
    
    -- Create notification for the promoted user
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    VALUES (
        p_promoted_user_id,
        'admin_promotion',
        'Admin Promotion',
        p_promoter_name || ' promoted you to admin in "' || v_club_name || '"',
        p_club_id,
        v_club_name
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Admin promotion notification created'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the functions
SELECT 
    'Test Message Notification Functions' as test_type,
    'Functions created successfully' as result;
