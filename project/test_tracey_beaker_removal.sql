-- Test the remove_friend_by_internal_id function specifically for Tracey Beaker
-- This will help us understand why it's failing for her but worked for Pauline

-- Test 1: Check Tracey Beaker's user info
SELECT 
    'Tracey Beaker Info' as test_type,
    u.id as internal_id,
    u.auth_user_id,
    u.name,
    u.username
FROM users u 
WHERE u.id = '309f3f29-aeea-4f26-a936-8d65047dc469';

-- Test 2: Check William Dumbili's user info (current user)
SELECT 
    'William Dumbili Info' as test_type,
    u.id as internal_id,
    u.auth_user_id,
    u.name,
    u.username
FROM users u 
WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

-- Test 3: Check the friendship between William and Tracey
SELECT 
    'William-Tracey Friendship' as test_type,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    u1.name as requester_name,
    u2.name as target_name
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE ((fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') 
        AND fr.target_id = '309f3f29-aeea-4f26-a936-8d65047dc469') OR 
       (fr.requester_id = '309f3f29-aeea-4f26-a936-8d65047dc469' 
        AND fr.target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9')))
AND fr.status = 'accepted';

-- Test 4: Test the function step by step (simulate what the function does)
DO $$
DECLARE
    test_auth_user_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9';
    test_friend_internal_id UUID := '309f3f29-aeea-4f26-a936-8d65047dc469';
    v_user_id UUID;
    v_friend_auth_user_id UUID;
    friendship_exists BOOLEAN;
BEGIN
    RAISE NOTICE '=== TESTING TRACEY BEAKER REMOVAL ===';
    RAISE NOTICE 'Input auth_user_id: %', test_auth_user_id;
    RAISE NOTICE 'Input friend_internal_id: %', test_friend_internal_id;
    
    -- Step 1: Get William's internal ID
    SELECT id INTO v_user_id FROM users WHERE auth_user_id = test_auth_user_id;
    RAISE NOTICE 'Step 1 - William internal ID: %', v_user_id;
    
    -- Step 2: Get Tracey's auth_user_id
    SELECT auth_user_id INTO v_friend_auth_user_id FROM users WHERE id = test_friend_internal_id;
    RAISE NOTICE 'Step 2 - Tracey auth_user_id: %', v_friend_auth_user_id;
    
    -- Step 3: Check if friendship exists
    SELECT EXISTS (
        SELECT 1 FROM friend_requests
        WHERE ((requester_id = v_user_id AND target_id = test_friend_internal_id) OR 
               (requester_id = test_friend_internal_id AND target_id = v_user_id))
        AND status = 'accepted'
    ) INTO friendship_exists;
    RAISE NOTICE 'Step 3 - Friendship exists: %', friendship_exists;
    
    -- Step 4: Test the actual function
    RAISE NOTICE 'Step 4 - Function result: %', remove_friend_by_internal_id(test_auth_user_id, test_friend_internal_id);
END $$;
