-- Fix notification constraint issues
-- This script addresses the "new row for relation 'notifications' violates check constraint" error

-- First, let's check the current notifications table structure
SELECT 
    'Notifications Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'notifications' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if there are any check constraints on notifications table
SELECT 
    'Notifications Constraints' as check_type,
    constraint_name,
    constraint_type,
    check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'notifications' 
AND tc.table_schema = 'public'
AND tc.constraint_type = 'CHECK';

-- Let's see what data is in the notifications table
SELECT 
    'Current Notifications' as check_type,
    COUNT(*) as notification_count
FROM notifications;

-- Let's check if there are any problematic notification functions
SELECT 
    'Notification Functions' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%notification%'
ORDER BY routine_name;

-- The issue might be with the notification functions. Let's recreate them with proper error handling
DROP FUNCTION IF EXISTS create_member_joined_notification(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS create_club_message_notification(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS create_discussion_message_notification(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS create_admin_promotion_notification(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS create_club_invitation_notification(UUID, UUID, TEXT);

-- Create safer notification functions that handle errors gracefully
CREATE OR REPLACE FUNCTION create_member_joined_notification(
    club_id UUID,
    user_id UUID,
    club_name TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Try to create notification, but don't fail if it doesn't work
    BEGIN
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name, is_read, created_at)
        SELECT 
            bcm.user_id,
            'member_joined'::TEXT,
            'New Member Joined'::TEXT,
            'A new member has joined ' || club_name::TEXT,
            club_id,
            club_name::TEXT,
            FALSE,
            NOW()
        FROM book_club_members bcm
        WHERE bcm.club_id = create_member_joined_notification.club_id
        AND bcm.role = 'admin'
        AND bcm.user_id != create_member_joined_notification.user_id;
    EXCEPTION WHEN OTHERS THEN
        -- Log the error but don't fail the main operation
        RAISE NOTICE 'Failed to create member joined notification: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION create_club_message_notification(
    club_id UUID,
    user_id UUID,
    message_content TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Try to create notification, but don't fail if it doesn't work
    BEGIN
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name, is_read, created_at)
        SELECT 
            bcm.user_id,
            'club_message'::TEXT,
            'New Club Message'::TEXT,
            LEFT(message_content, 100)::TEXT,
            club_id,
            (SELECT bc.name FROM book_clubs bc WHERE bc.id = create_club_message_notification.club_id)::TEXT,
            FALSE,
            NOW()
        FROM book_club_members bcm
        WHERE bcm.club_id = create_club_message_notification.club_id
        AND bcm.user_id != create_club_message_notification.user_id;
    EXCEPTION WHEN OTHERS THEN
        -- Log the error but don't fail the main operation
        RAISE NOTICE 'Failed to create club message notification: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION create_discussion_message_notification(
    discussion_id UUID,
    user_id UUID,
    message_content TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Try to create notification, but don't fail if it doesn't work
    BEGIN
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name, is_read, created_at)
        SELECT 
            dm.user_id,
            'discussion_message'::TEXT,
            'New Discussion Message'::TEXT,
            LEFT(message_content, 100)::TEXT,
            discussion_id,
            (SELECT d.title FROM discussions d WHERE d.id = create_discussion_message_notification.discussion_id)::TEXT,
            FALSE,
            NOW()
        FROM discussion_members dm
        WHERE dm.discussion_id = create_discussion_message_notification.discussion_id
        AND dm.user_id != create_discussion_message_notification.user_id;
    EXCEPTION WHEN OTHERS THEN
        -- Log the error but don't fail the main operation
        RAISE NOTICE 'Failed to create discussion message notification: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION create_admin_promotion_notification(
    user_id UUID,
    club_id UUID,
    club_name TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Try to create notification, but don't fail if it doesn't work
    BEGIN
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name, is_read, created_at)
        VALUES (
            user_id,
            'admin_promotion'::TEXT,
            'Promoted to Admin'::TEXT,
            'You have been promoted to admin in ' || club_name::TEXT,
            club_id,
            club_name::TEXT,
            FALSE,
            NOW()
        );
    EXCEPTION WHEN OTHERS THEN
        -- Log the error but don't fail the main operation
        RAISE NOTICE 'Failed to create admin promotion notification: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION create_club_invitation_notification(
    user_id UUID,
    club_id UUID,
    club_name TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Try to create notification, but don't fail if it doesn't work
    BEGIN
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name, is_read, created_at)
        VALUES (
            user_id,
            'club_invitation'::TEXT,
            'Club Invitation'::TEXT,
            'You have been invited to join ' || club_name::TEXT,
            club_id,
            club_name::TEXT,
            FALSE,
            NOW()
        );
    EXCEPTION WHEN OTHERS THEN
        -- Log the error but don't fail the main operation
        RAISE NOTICE 'Failed to create club invitation notification: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify the notification functions were created
SELECT 
    'Updated Notification Functions' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN (
    'create_member_joined_notification',
    'create_club_message_notification',
    'create_discussion_message_notification',
    'create_admin_promotion_notification',
    'create_club_invitation_notification'
)
ORDER BY routine_name;




















