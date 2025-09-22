-- Test friend functions to diagnose 400 errors
-- Run this to check if the functions exist and work

-- 1. Check if functions exist
SELECT 
    'FUNCTION_EXISTS_CHECK' as test,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_friend_requests', 'get_friend_connections', 'get_friend_recommendations')
ORDER BY routine_name;

-- 2. Test get_friend_requests with a sample user ID
-- Replace 'your-user-id-here' with an actual user ID from your users table
SELECT 
    'GET_FRIEND_REQUESTS_TEST' as test,
    COUNT(*) as result_count
FROM get_friend_requests('your-user-id-here'::UUID);

-- 3. Test get_friend_connections with a sample user ID
SELECT 
    'GET_FRIEND_CONNECTIONS_TEST' as test,
    COUNT(*) as result_count
FROM get_friend_connections('your-user-id-here'::UUID);

-- 4. Test get_friend_recommendations with a sample user ID
SELECT 
    'GET_FRIEND_RECOMMENDATIONS_TEST' as test,
    COUNT(*) as result_count
FROM get_friend_recommendations('your-user-id-here'::UUID);

-- 5. Check if friend_requests table exists and has data
SELECT 
    'FRIEND_REQUESTS_TABLE_CHECK' as test,
    COUNT(*) as total_requests
FROM friend_requests;

-- 6. Show sample user IDs to use in tests above
SELECT 
    'SAMPLE_USER_IDS' as test,
    id,
    name,
    username
FROM users
LIMIT 3;
