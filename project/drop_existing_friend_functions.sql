-- Drop existing friend functions that might conflict
-- This script should be run BEFORE create_missing_friend_functions.sql

-- Drop all variations of friend functions
DROP FUNCTION IF EXISTS get_friend_requests(UUID);
DROP FUNCTION IF EXISTS get_friend_connections(UUID);
DROP FUNCTION IF EXISTS get_friend_recommendations(UUID);
DROP FUNCTION IF EXISTS generate_friend_recommendations(UUID);
DROP FUNCTION IF EXISTS send_friend_request(UUID, UUID);
DROP FUNCTION IF EXISTS send_friend_request(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS accept_friend_request(UUID, UUID);
DROP FUNCTION IF EXISTS reject_friend_request(UUID, UUID);
DROP FUNCTION IF EXISTS remove_friend(UUID, UUID);
DROP FUNCTION IF EXISTS block_friend(UUID, UUID);
DROP FUNCTION IF EXISTS unblock_user(UUID, UUID);
DROP FUNCTION IF EXISTS get_blocked_users(UUID);

-- Also check for variations with different parameter names
DROP FUNCTION IF EXISTS get_friend_requests(auth_user_id UUID);
DROP FUNCTION IF EXISTS get_friend_connections(auth_user_id UUID);
DROP FUNCTION IF EXISTS get_friend_recommendations(auth_user_id UUID);
DROP FUNCTION IF EXISTS generate_friend_recommendations(auth_user_id UUID);
DROP FUNCTION IF EXISTS send_friend_request(auth_user_id UUID, target_user_id UUID);
DROP FUNCTION IF EXISTS send_friend_request(auth_user_id UUID, target_user_id UUID, message TEXT);
DROP FUNCTION IF EXISTS accept_friend_request(auth_user_id UUID, requester_user_id UUID);
DROP FUNCTION IF EXISTS reject_friend_request(auth_user_id UUID, requester_user_id UUID);

-- Check what functions exist after dropping
SELECT 
    'REMAINING FRIEND FUNCTIONS' as info,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%friend%'
ORDER BY routine_name;
