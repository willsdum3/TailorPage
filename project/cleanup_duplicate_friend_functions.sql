-- Clean up duplicate friend functions
-- This will remove all friend functions and recreate them cleanly

-- Drop ALL friend functions to avoid conflicts
DROP FUNCTION IF EXISTS accept_friend_request(UUID, UUID);
DROP FUNCTION IF EXISTS accept_friend_request(auth_user_id UUID, requester_user_id UUID);
DROP FUNCTION IF EXISTS block_friend(UUID, UUID);
DROP FUNCTION IF EXISTS generate_friend_recommendations(UUID);
DROP FUNCTION IF EXISTS generate_friend_recommendations(auth_user_id UUID);
DROP FUNCTION IF EXISTS get_friend_connections(UUID);
DROP FUNCTION IF EXISTS get_friend_connections(auth_user_id UUID);
DROP FUNCTION IF EXISTS get_friend_conversations(UUID);
DROP FUNCTION IF EXISTS get_friend_messages(UUID, UUID);
DROP FUNCTION IF EXISTS get_friend_recommendations(UUID);
DROP FUNCTION IF EXISTS get_friend_recommendations(auth_user_id UUID);
DROP FUNCTION IF EXISTS get_friend_requests(UUID);
DROP FUNCTION IF EXISTS get_friend_requests(auth_user_id UUID);
DROP FUNCTION IF EXISTS reject_friend_request(UUID, UUID);
DROP FUNCTION IF EXISTS reject_friend_request(auth_user_id UUID, requester_user_id UUID);
DROP FUNCTION IF EXISTS remove_friend(UUID, UUID);
DROP FUNCTION IF EXISTS send_friend_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS send_friend_request(UUID, UUID);
DROP FUNCTION IF EXISTS send_friend_request(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS send_friend_request(auth_user_id UUID, target_user_id UUID);
DROP FUNCTION IF EXISTS send_friend_request(auth_user_id UUID, target_user_id UUID, message TEXT);

-- Verify all functions are dropped
SELECT 
    'FUNCTIONS_AFTER_CLEANUP' as info,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%friend%'
ORDER BY routine_name;
