-- Test both versions of get_friend_connections to see which one is working

-- Test version 1 (with user_clerk_id parameter)
-- This should fail because it's looking for a friend_connections table that doesn't exist
SELECT 
    'Version 1 Test (user_clerk_id)' as test_type,
    get_friend_connections('3bd64865-45b6-4b2b-81d2-4940a8bf3200'::TEXT) as result;

-- Test version 2 (with p_auth_user_id parameter) 
-- This should work because it queries the friend_requests table
SELECT 
    'Version 2 Test (p_auth_user_id)' as test_type,
    get_friend_connections('3bd64865-45b6-4b2b-81d2-4940a8bf3200'::UUID) as result;

-- Check if friend_connections table exists
SELECT 
    'Table Check' as test_type,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('friend_connections', 'friend_requests')
AND table_schema = 'public';
