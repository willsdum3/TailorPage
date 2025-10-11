-- Diagnose Discussion Data Issues
-- Simple script to check what data exists in the database

-- Check what's in the users table
SELECT 
    'Users Table Data' as check_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN name IS NOT NULL AND name != '' THEN 1 END) as users_with_names,
    COUNT(CASE WHEN username IS NOT NULL AND username != '' THEN 1 END) as users_with_usernames,
    COUNT(CASE WHEN avatar_url IS NOT NULL AND avatar_url != '' THEN 1 END) as users_with_avatars
FROM users;

-- Show sample users data
SELECT 
    'Sample Users' as check_type,
    id,
    name,
    username,
    avatar_url,
    email
FROM users 
LIMIT 3;

-- Check what's in the discussion_messages table
SELECT 
    'Discussion Messages Data' as check_type,
    COUNT(*) as total_messages,
    COUNT(CASE WHEN content IS NOT NULL AND content != '' THEN 1 END) as messages_with_content,
    COUNT(CASE WHEN message IS NOT NULL AND message != '' THEN 1 END) as messages_with_message
FROM discussion_messages;

-- Show sample discussion messages with user data
SELECT 
    'Sample Discussion Messages' as check_type,
    dm.id,
    dm.content,
    dm.message,
    dm.created_at,
    u.name as user_name,
    u.username as user_username,
    u.avatar_url as user_avatar_url,
    u.email as user_email
FROM discussion_messages dm
JOIN users u ON dm.user_id = u.id
LIMIT 3;

-- Check if there are any discussions
SELECT 
    'Discussions Data' as check_type,
    COUNT(*) as total_discussions
FROM discussions;

-- Test the function directly with a simple query
SELECT 
    'Function Test' as check_type,
    'Testing get_discussion_messages function...' as message;

-- Try to call the function if there are any discussions and users
DO $$
DECLARE
    test_user_id UUID;
    test_discussion_id UUID;
    message_count INTEGER := 0;
BEGIN
    -- Get the first available user and discussion
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT d.id INTO test_discussion_id FROM discussions d LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_discussion_id IS NOT NULL THEN
        BEGIN
            -- Count messages using the function
            SELECT COUNT(*) INTO message_count 
            FROM get_discussion_messages(test_user_id, test_discussion_id, 10, 0);
            
            RAISE NOTICE 'Function test: Found % messages for discussion %', message_count, test_discussion_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Function test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'No test data available - need at least 1 user and 1 discussion';
    END IF;
END $$;
