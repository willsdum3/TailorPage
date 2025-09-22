-- Diagnose friend functions - automatically finds real user IDs
-- This script will work without needing to manually replace user IDs

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

-- 2. Check if friend_requests table exists and has data
SELECT 
    'FRIEND_REQUESTS_TABLE_CHECK' as test,
    COUNT(*) as total_requests
FROM friend_requests;

-- 3. Show sample user IDs from your users table
SELECT 
    'SAMPLE_USER_IDS' as test,
    id,
    name,
    username
FROM users
LIMIT 3;

-- 4. Test functions with the first available user ID (if any exist)
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Get the first user ID
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with user ID: %', test_user_id;
        
        -- Test get_friend_requests
        BEGIN
            PERFORM * FROM get_friend_requests(test_user_id) LIMIT 1;
            RAISE NOTICE 'get_friend_requests: SUCCESS';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'get_friend_requests: ERROR - %', SQLERRM;
        END;
        
        -- Test get_friend_connections
        BEGIN
            PERFORM * FROM get_friend_connections(test_user_id) LIMIT 1;
            RAISE NOTICE 'get_friend_connections: SUCCESS';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'get_friend_connections: ERROR - %', SQLERRM;
        END;
        
        -- Test get_friend_recommendations
        BEGIN
            PERFORM * FROM get_friend_recommendations(test_user_id) LIMIT 1;
            RAISE NOTICE 'get_friend_recommendations: SUCCESS';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'get_friend_recommendations: ERROR - %', SQLERRM;
        END;
        
    ELSE
        RAISE NOTICE 'No users found in the users table';
    END IF;
END $$;

-- 5. Check function parameters
SELECT 
    'FUNCTION_PARAMETERS' as test,
    p.routine_name,
    p.parameter_name,
    p.data_type
FROM information_schema.parameters p
WHERE p.specific_schema = 'public' 
AND p.routine_name IN ('get_friend_requests', 'get_friend_connections', 'get_friend_recommendations')
ORDER BY p.routine_name, p.ordinal_position;
