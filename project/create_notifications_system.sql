-- Create comprehensive notifications system for Tailor Mates
-- This will handle all notification types: messages, friend requests, club invitations, admin promotions, etc.

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN (
        'club_message', 
        'discussion_message', 
        'friend_message', 
        'friend_request', 
        'club_invitation', 
        'admin_promotion',
        'user_joined_club'
    )),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    related_id UUID, -- ID of related entity (club, discussion, friend, etc.)
    related_name TEXT, -- Name of related entity for display
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (drop existing ones first)
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can delete their own notifications" ON notifications;

CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE USING (user_id = auth.uid()::uuid);

-- Function to get notifications for a user
DROP FUNCTION IF EXISTS get_notifications(UUID, INTEGER, INTEGER, BOOLEAN);
CREATE OR REPLACE FUNCTION get_notifications(
    p_auth_user_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_unread_only BOOLEAN DEFAULT FALSE
)
RETURNS TABLE(
    id UUID,
    type CHARACTER VARYING(50),
    title TEXT,
    message TEXT,
    related_id UUID,
    related_name TEXT,
    is_read BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the user's internal ID
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    RETURN QUERY
    SELECT 
        n.id,
        n.type,
        n.title,
        n.message,
        n.related_id,
        n.related_name,
        n.is_read,
        n.created_at
    FROM notifications n
    WHERE n.user_id = v_user_id
    AND (NOT p_unread_only OR n.is_read = FALSE)
    ORDER BY n.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark notification as read
DROP FUNCTION IF EXISTS mark_notification_as_read(UUID, UUID);
CREATE OR REPLACE FUNCTION mark_notification_as_read(
    p_auth_user_id UUID,
    p_notification_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_result JSONB;
BEGIN
    -- Get the user's internal ID
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Update the notification
    UPDATE notifications 
    SET is_read = TRUE, updated_at = NOW()
    WHERE id = p_notification_id AND user_id = v_user_id;
    
    IF FOUND THEN
        v_result := jsonb_build_object('success', true, 'message', 'Notification marked as read');
    ELSE
        v_result := jsonb_build_object('success', false, 'error', 'Notification not found');
    END IF;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all notifications as read
DROP FUNCTION IF EXISTS mark_all_notifications_as_read(UUID);
CREATE OR REPLACE FUNCTION mark_all_notifications_as_read(
    p_auth_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_updated_count INTEGER;
BEGIN
    -- Get the user's internal ID
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Update all unread notifications
    UPDATE notifications 
    SET is_read = TRUE, updated_at = NOW()
    WHERE user_id = v_user_id AND is_read = FALSE;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN jsonb_build_object(
        'success', true, 
        'message', 'All notifications marked as read',
        'updated_count', v_updated_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete notification
DROP FUNCTION IF EXISTS delete_notification(UUID, UUID);
CREATE OR REPLACE FUNCTION delete_notification(
    p_auth_user_id UUID,
    p_notification_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the user's internal ID
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Delete the notification
    DELETE FROM notifications 
    WHERE id = p_notification_id AND user_id = v_user_id;
    
    IF FOUND THEN
        RETURN jsonb_build_object('success', true, 'message', 'Notification deleted');
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Notification not found');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread notification count
DROP FUNCTION IF EXISTS get_unread_notification_count(UUID);
CREATE OR REPLACE FUNCTION get_unread_notification_count(
    p_auth_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_user_id UUID;
    v_count INTEGER;
BEGIN
    -- Get the user's internal ID
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Count unread notifications
    SELECT COUNT(*) INTO v_count
    FROM notifications
    WHERE user_id = v_user_id AND is_read = FALSE;
    
    RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create a notification
DROP FUNCTION IF EXISTS create_notification(UUID, TEXT, TEXT, TEXT, UUID, TEXT);
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id UUID,
    p_type TEXT,
    p_title TEXT,
    p_message TEXT,
    p_related_id UUID DEFAULT NULL,
    p_related_name TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    -- Insert the notification
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    VALUES (p_user_id, p_type, p_title, p_message, p_related_id, p_related_name)
    RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the functions
SELECT 
    'Test Notifications System' as test_type,
    'Functions created successfully' as result;
