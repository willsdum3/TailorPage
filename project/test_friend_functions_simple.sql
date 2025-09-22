-- Simple test for friend functions
-- This will test if the functions work with a real user ID

-- 1. Get a real user ID to test with
SELECT 
    'TEST_USER_ID' as info,
    id,
    name,
    username
FROM users
LIMIT 1;

-- 2. Test get_friend_requests function
-- Replace 'USER_ID_HERE' with the actual user ID from step 1
DO $$
DECLARE
    test_user_id UUID;
    result_count INTEGER;
BEGIN
    -- Get first user ID
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with user ID: %', test_user_id;
        
        -- Test get_friend_requests
        SELECT COUNT(*) INTO result_count FROM get_friend_requests(test_user_id);
        RAISE NOTICE 'get_friend_requests returned % rows', result_count;
        
        -- Test get_friend_connections  
        SELECT COUNT(*) INTO result_count FROM get_friend_connections(test_user_id);
        RAISE NOTICE 'get_friend_connections returned % rows', result_count;
        
        -- Test get_friend_recommendations
        SELECT COUNT(*) INTO result_count FROM get_friend_recommendations(test_user_id);
        RAISE NOTICE 'get_friend_recommendations returned % rows', result_count;
        
    ELSE
        RAISE NOTICE 'No users found in database';
    END IF;
END $$;
