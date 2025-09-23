-- Debug the 400 errors in messaging system
-- This script will help identify why getFriendMessages is failing

-- First, let's check what conversations exist
SELECT 
    'EXISTING CONVERSATIONS' as info,
    fc.id as conversation_id,
    fc.user1_id,
    fc.user2_id,
    u1.name as user1_name,
    u1.username as user1_username,
    u2.name as user2_name,
    u2.username as user2_username,
    fc.created_at
FROM friend_conversations fc
LEFT JOIN users u1 ON fc.user1_id = u1.id
LEFT JOIN users u2 ON fc.user2_id = u2.id
ORDER BY fc.created_at DESC;

-- Check what messages exist
SELECT 
    'EXISTING MESSAGES' as info,
    fm.id as message_id,
    fm.conversation_id,
    fm.sender_id,
    fm.content,
    fm.created_at,
    u.name as sender_name,
    u.username as sender_username
FROM friend_messages fm
LEFT JOIN users u ON fm.sender_id = u.id
ORDER BY fm.created_at DESC;

-- Test the get_friend_conversations function with a real user
SELECT 
    'GET CONVERSATIONS TEST' as info,
    *
FROM get_friend_conversations(
    (SELECT auth_user_id FROM users LIMIT 1)
);

-- Test the get_friend_messages function with the conversation ID from above
-- First, let's get a conversation ID to test with
WITH test_conversation AS (
    SELECT id FROM friend_conversations LIMIT 1
)
SELECT 
    'GET MESSAGES TEST' as info,
    *
FROM get_friend_messages(
    (SELECT auth_user_id FROM users LIMIT 1),
    (SELECT id FROM test_conversation),
    10,
    0
);

-- Check if there are any RLS policies that might be blocking access
SELECT 
    'RLS POLICIES' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('friend_conversations', 'friend_messages')
ORDER BY tablename, policyname;
