-- Test the messaging functions with real data
-- This will help verify that the functions work correctly

-- First, let's get some real user IDs to test with
SELECT 
    'AVAILABLE USERS' as info,
    id,
    name,
    username,
    auth_user_id
FROM users 
ORDER BY created_at DESC
LIMIT 5;

-- Test the get_friend_messages function with a real user
-- Replace 'your-auth-user-id-here' with an actual auth_user_id from above
SELECT 
    'TEST GET MESSAGES' as info,
    *
FROM get_friend_messages(
    (SELECT auth_user_id FROM users LIMIT 1), -- Use first user's auth_user_id
    md5('test-conversation')::uuid, -- Use a test conversation ID
    10,
    0
);

-- Test sending a message (this will create a real message in the database)
-- Replace the user IDs with real ones from the users table
SELECT 
    'TEST SEND MESSAGE' as info,
    send_friend_message(
        (SELECT auth_user_id FROM users LIMIT 1), -- Sender's auth_user_id
        (SELECT id FROM users LIMIT 1 OFFSET 1), -- Friend's internal user ID
        'This is a test message from the database function!'
    );

-- Check if the message was actually stored
SELECT 
    'STORED MESSAGES' as info,
    fm.id,
    fm.conversation_id,
    fm.sender_id,
    fm.content,
    fm.created_at,
    u.name as sender_name,
    u.username as sender_username
FROM friend_messages fm
JOIN users u ON fm.sender_id = u.id
ORDER BY fm.created_at DESC
LIMIT 5;
