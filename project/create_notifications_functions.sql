-- Create Notifications system functions
-- This script creates all functions for the comprehensive notifications system

-- =====================================================
-- NOTIFICATION FUNCTIONS
-- =====================================================

-- Get notifications for a user
CREATE OR REPLACE FUNCTION get_notifications(
    p_auth_user_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_unread_only BOOLEAN DEFAULT FALSE
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_notifications JSON;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_array();
    END IF;
    
    -- Get notifications
    SELECT json_agg(
        json_build_object(
            'id', n.id,
            'userId', n.user_id,
            'type', n.type,
            'title', n.title,
            'message', n.message,
            'relatedId', n.related_id,
            'relatedName', n.related_name,
            'isRead', n.is_read,
            'createdAt', n.created_at
        ) ORDER BY n.created_at DESC
    ) INTO v_notifications
    FROM notifications n
    WHERE n.user_id = v_user_id
    AND (NOT p_unread_only OR n.is_read = FALSE)
    ORDER BY n.created_at DESC
    LIMIT p_limit OFFSET p_offset;
    
    RETURN COALESCE(v_notifications, json_build_array());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_as_read(
    p_auth_user_id UUID,
    p_notification_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_updated_count INTEGER;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Update notification
    UPDATE notifications
    SET is_read = TRUE, updated_at = NOW()
    WHERE id = p_notification_id AND user_id = v_user_id;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    IF v_updated_count = 0 THEN
        RETURN json_build_object('success', false, 'error', 'Notification not found');
    END IF;
    
    RETURN json_build_object('success', true, 'message', 'Notification marked as read');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mark all notifications as read
CREATE OR REPLACE FUNCTION mark_all_notifications_as_read(
    p_auth_user_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_updated_count INTEGER;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Update all unread notifications
    UPDATE notifications
    SET is_read = TRUE, updated_at = NOW()
    WHERE user_id = v_user_id AND is_read = FALSE;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN json_build_object(
        'success', true, 
        'message', v_updated_count || ' notifications marked as read'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Delete notification
CREATE OR REPLACE FUNCTION delete_notification(
    p_auth_user_id UUID,
    p_notification_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_deleted_count INTEGER;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Delete notification
    DELETE FROM notifications
    WHERE id = p_notification_id AND user_id = v_user_id;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    IF v_deleted_count = 0 THEN
        RETURN json_build_object('success', false, 'error', 'Notification not found');
    END IF;
    
    RETURN json_build_object('success', true, 'message', 'Notification deleted');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count(
    p_auth_user_id UUID
) RETURNS INTEGER AS $$
DECLARE
    v_user_id UUID;
    v_count INTEGER;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Count unread notifications
    SELECT COUNT(*)::INTEGER INTO v_count
    FROM notifications
    WHERE user_id = v_user_id AND is_read = FALSE;
    
    RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- NOTIFICATION CREATION HELPERS
-- =====================================================

-- Create club message notification
CREATE OR REPLACE FUNCTION create_club_message_notification(
    p_club_id UUID,
    p_sender_id UUID,
    p_message_content TEXT
) RETURNS VOID AS $$
DECLARE
    v_club_name TEXT;
    v_sender_name TEXT;
    v_member RECORD;
BEGIN
    -- Get club and sender info
    SELECT name INTO v_club_name FROM book_clubs WHERE id = p_club_id;
    SELECT name INTO v_sender_name FROM users WHERE id = p_sender_id;
    
    -- Create notifications for all club members except the sender
    FOR v_member IN 
        SELECT cm.user_id
        FROM club_memberships cm
        WHERE cm.club_id = p_club_id 
        AND cm.user_id != p_sender_id
    LOOP
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
        VALUES (
            v_member.user_id,
            'club_message',
            'New Club Message',
            v_sender_name || ' posted in ' || v_club_name,
            p_club_id,
            v_club_name
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create discussion message notification
CREATE OR REPLACE FUNCTION create_discussion_message_notification(
    p_discussion_id UUID,
    p_sender_id UUID,
    p_message_content TEXT
) RETURNS VOID AS $$
DECLARE
    v_discussion_title TEXT;
    v_sender_name TEXT;
    v_participant RECORD;
BEGIN
    -- Get discussion and sender info
    SELECT title INTO v_discussion_title FROM discussions WHERE id = p_discussion_id;
    SELECT name INTO v_sender_name FROM users WHERE id = p_sender_id;
    
    -- Create notifications for all discussion participants except the sender
    FOR v_participant IN 
        SELECT dp.user_id
        FROM discussion_participants dp
        WHERE dp.discussion_id = p_discussion_id 
        AND dp.user_id != p_sender_id
    LOOP
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
        VALUES (
            v_participant.user_id,
            'discussion_message',
            'New Discussion Reply',
            v_sender_name || ' replied to ' || v_discussion_title,
            p_discussion_id,
            v_discussion_title
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create admin promotion notification
CREATE OR REPLACE FUNCTION create_admin_promotion_notification(
    p_club_id UUID,
    p_promoted_user_id UUID,
    p_promoter_id UUID
) RETURNS VOID AS $$
DECLARE
    v_club_name TEXT;
    v_promoter_name TEXT;
BEGIN
    -- Get club and promoter info
    SELECT name INTO v_club_name FROM book_clubs WHERE id = p_club_id;
    SELECT name INTO v_promoter_name FROM users WHERE id = p_promoter_id;
    
    -- Create notification for promoted user
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    VALUES (
        p_promoted_user_id,
        'admin_promotion',
        'You''re now an Admin!',
        'You have been promoted to admin in ' || v_club_name || ' by ' || v_promoter_name,
        p_club_id,
        v_club_name
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create club invitation notification
CREATE OR REPLACE FUNCTION create_club_invitation_notification(
    p_club_id UUID,
    p_invited_user_id UUID,
    p_inviter_id UUID
) RETURNS VOID AS $$
DECLARE
    v_club_name TEXT;
    v_inviter_name TEXT;
BEGIN
    -- Get club and inviter info
    SELECT name INTO v_club_name FROM book_clubs WHERE id = p_club_id;
    SELECT name INTO v_inviter_name FROM users WHERE id = p_inviter_id;
    
    -- Create notification for invited user
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    VALUES (
        p_invited_user_id,
        'club_invitation',
        'Book Club Invitation',
        v_inviter_name || ' invited you to join ' || v_club_name,
        p_club_id,
        v_club_name
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- NOTIFICATION CLEANUP
-- =====================================================

-- Clean up old notifications (older than 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM notifications
    WHERE created_at < NOW() - INTERVAL '30 days'
    AND is_read = TRUE;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
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
    'get_notifications',
    'mark_notification_as_read',
    'mark_all_notifications_as_read',
    'delete_notification',
    'get_unread_notification_count',
    'create_club_message_notification',
    'create_discussion_message_notification',
    'create_admin_promotion_notification',
    'create_club_invitation_notification',
    'cleanup_old_notifications'
)
ORDER BY routine_name;
