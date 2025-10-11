-- Comprehensive test script for the notifications system
-- This will test all notification types and functions

-- Test 1: Check if notifications table exists and has correct structure
SELECT 
    'Test 1: Notifications Table Structure' as test_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'notifications' 
ORDER BY ordinal_position;

-- Test 2: Check if all notification functions exist
SELECT 
    'Test 2: Notification Functions' as test_name,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%notification%'
ORDER BY routine_name;

-- Test 3: Check if notification triggers exist
SELECT 
    'Test 3: Notification Triggers' as test_name,
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND trigger_name LIKE '%notification%'
ORDER BY trigger_name;

-- Test 4: Test creating a sample notification
DO $$
DECLARE
    v_test_user_id UUID;
    v_notification_id UUID;
BEGIN
    -- Get a test user ID
    SELECT id INTO v_test_user_id FROM users LIMIT 1;
    
    IF v_test_user_id IS NOT NULL THEN
        -- Create a test notification
        SELECT create_notification(
            v_test_user_id,
            'friend_request',
            'Test Notification',
            'This is a test notification to verify the system works',
            v_test_user_id,
            'Test User'
        ) INTO v_notification_id;
        
        RAISE NOTICE 'Test 4: Created test notification with ID: %', v_notification_id;
    ELSE
        RAISE NOTICE 'Test 4: No users found to test with';
    END IF;
END $$;

-- Test 5: Test getting notifications
DO $$
DECLARE
    v_test_auth_user_id UUID;
    v_notification_count INTEGER;
BEGIN
    -- Get a test user's auth_user_id
    SELECT auth_user_id INTO v_test_auth_user_id FROM users LIMIT 1;
    
    IF v_test_auth_user_id IS NOT NULL THEN
        -- Test getting notifications
        SELECT COUNT(*) INTO v_notification_count
        FROM get_notifications(v_test_auth_user_id, 10, 0, false);
        
        RAISE NOTICE 'Test 5: Found % notifications for test user', v_notification_count;
    ELSE
        RAISE NOTICE 'Test 5: No users found to test with';
    END IF;
END $$;

-- Test 6: Test unread notification count
DO $$
DECLARE
    v_test_auth_user_id UUID;
    v_unread_count INTEGER;
BEGIN
    -- Get a test user's auth_user_id
    SELECT auth_user_id INTO v_test_auth_user_id FROM users LIMIT 1;
    
    IF v_test_auth_user_id IS NOT NULL THEN
        -- Test getting unread count
        SELECT get_unread_notification_count(v_test_auth_user_id) INTO v_unread_count;
        
        RAISE NOTICE 'Test 6: Unread notification count: %', v_unread_count;
    ELSE
        RAISE NOTICE 'Test 6: No users found to test with';
    END IF;
END $$;

-- Test 7: Test notification triggers (if we have sample data)
SELECT 
    'Test 7: Sample Data Check' as test_name,
    'friend_requests' as table_name,
    COUNT(*) as record_count
FROM friend_requests
UNION ALL
SELECT 
    'Test 7: Sample Data Check' as test_name,
    'club_memberships' as table_name,
    COUNT(*) as record_count
FROM club_memberships
UNION ALL
SELECT 
    'Test 7: Sample Data Check' as test_name,
    'notifications' as table_name,
    COUNT(*) as record_count
FROM notifications;

-- Test 8: Test message notification functions (if we have sample data)
DO $$
DECLARE
    v_test_club_id UUID;
    v_test_discussion_id UUID;
    v_test_conversation_id UUID;
    v_test_sender_id UUID;
    v_result JSONB;
BEGIN
    -- Get sample data
    SELECT id INTO v_test_club_id FROM book_clubs LIMIT 1;
    SELECT id INTO v_test_discussion_id FROM discussions LIMIT 1;
    SELECT id INTO v_test_conversation_id FROM friend_conversations LIMIT 1;
    SELECT id INTO v_test_sender_id FROM users LIMIT 1;
    
    -- Test club message notification
    IF v_test_club_id IS NOT NULL AND v_test_sender_id IS NOT NULL THEN
        SELECT create_club_message_notification(
            v_test_club_id,
            v_test_sender_id,
            'Test club message'
        ) INTO v_result;
        RAISE NOTICE 'Test 8a: Club message notification result: %', v_result;
    END IF;
    
    -- Test discussion message notification
    IF v_test_discussion_id IS NOT NULL AND v_test_sender_id IS NOT NULL THEN
        SELECT create_discussion_message_notification(
            v_test_discussion_id,
            v_test_sender_id,
            'Test discussion message'
        ) INTO v_result;
        RAISE NOTICE 'Test 8b: Discussion message notification result: %', v_result;
    END IF;
    
    -- Test friend message notification
    IF v_test_conversation_id IS NOT NULL AND v_test_sender_id IS NOT NULL THEN
        SELECT create_friend_message_notification(
            v_test_conversation_id,
            v_test_sender_id,
            'Test friend message'
        ) INTO v_result;
        RAISE NOTICE 'Test 8c: Friend message notification result: %', v_result;
    END IF;
END $$;

-- Final summary
SELECT 
    'NOTIFICATION SYSTEM TEST COMPLETE' as status,
    'All tests have been executed. Check the NOTICE messages above for results.' as message;


