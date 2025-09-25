-- Comprehensive debug for friend removal issue
-- This will help us understand the exact problem

-- Step 1: Check if the function exists
SELECT 
    'Function Check' as test_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'remove_friend_by_internal_id'
AND routine_schema = 'public';

-- Step 2: Get William Dumbili's user info (current user)
SELECT 
    'Current User Info' as test_type,
    u.id as internal_id,
    u.auth_user_id,
    u.name,
    u.username
FROM users u 
WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

-- Step 3: Get Pauline Dumbili's user info (friend to remove)
SELECT 
    'Friend User Info' as test_type,
    u.id as internal_id,
    u.auth_user_id,
    u.name,
    u.username
FROM users u 
WHERE u.id = 'baf44ea3-ca65-43a7-8b16-18d16370b697';

-- Step 4: Check all friend relationships for William
SELECT 
    'All William Friendships' as test_type,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    u1.name as requester_name,
    u2.name as target_name,
    CASE 
        WHEN fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') THEN 'William is requester'
        WHEN fr.target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') THEN 'William is target'
        ELSE 'Unknown relationship'
    END as relationship_type
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9')
   OR fr.target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9');

-- Step 5: Test the function with debug output
DO $$
DECLARE
    test_auth_user_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9';
    test_friend_internal_id UUID := 'baf44ea3-ca65-43a7-8b16-18d16370b697';
    result JSON;
    v_user_id UUID;
    v_friend_auth_user_id UUID;
BEGIN
    RAISE NOTICE '=== TESTING REMOVE FRIEND FUNCTION ===';
    RAISE NOTICE 'Input auth_user_id: %', test_auth_user_id;
    RAISE NOTICE 'Input friend_internal_id: %', test_friend_internal_id;
    
    -- Test the lookups manually
    SELECT id INTO v_user_id FROM users WHERE auth_user_id = test_auth_user_id;
    RAISE NOTICE 'Found user internal ID: %', v_user_id;
    
    SELECT auth_user_id INTO v_friend_auth_user_id FROM users WHERE id = test_friend_internal_id;
    RAISE NOTICE 'Found friend auth_user_id: %', v_friend_auth_user_id;
    
    -- Test the function
    SELECT remove_friend_by_internal_id(test_auth_user_id, test_friend_internal_id) INTO result;
    RAISE NOTICE 'Function result: %', result;
END $$;
