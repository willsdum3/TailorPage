-- Simple debug script for remove_friend_by_internal_id function
-- This will help us understand why it's returning "Friend not found"

DO $$
DECLARE
    test_auth_user_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'; -- William's auth_user_id
    test_friend_internal_id UUID := 'baf44ea3-ca65-43a7-8b16-18d16370b697'; -- Pauline's internal_id
    current_user_internal_id UUID;
    friend_auth_user_id UUID;
    friendship_exists BOOLEAN;
    result JSON;
BEGIN
    RAISE NOTICE '=== DEBUGGING remove_friend_by_internal_id FUNCTION ===';
    
    -- Step 1: Get current user's internal ID
    SELECT id INTO current_user_internal_id 
    FROM users 
    WHERE auth_user_id = test_auth_user_id;
    
    RAISE NOTICE 'Step 1 - Current user internal ID: %', current_user_internal_id;
    
    -- Step 2: Get friend's auth_user_id
    SELECT auth_user_id INTO friend_auth_user_id 
    FROM users 
    WHERE id = test_friend_internal_id;
    
    RAISE NOTICE 'Step 2 - Friend auth_user_id: %', friend_auth_user_id;
    
    -- Step 3: Check if friendship exists
    SELECT EXISTS(
        SELECT 1 FROM friend_requests 
        WHERE ((requester_id = current_user_internal_id AND target_id = test_friend_internal_id)
               OR (requester_id = test_friend_internal_id AND target_id = current_user_internal_id))
        AND status = 'accepted'
    ) INTO friendship_exists;
    
    RAISE NOTICE 'Step 3 - Friendship exists: %', friendship_exists;
    
    -- Step 4: Show all friend_requests for these users (simple query)
    RAISE NOTICE 'Step 4 - All friend_requests involving these users:';
    PERFORM id, requester_id, target_id, status, created_at
    FROM friend_requests 
    WHERE (requester_id = current_user_internal_id OR target_id = current_user_internal_id)
       OR (requester_id = test_friend_internal_id OR target_id = test_friend_internal_id)
    ORDER BY created_at DESC;
    
    -- Step 5: Test the actual function
    RAISE NOTICE 'Step 5 - Testing remove_friend_by_internal_id function:';
    SELECT remove_friend_by_internal_id(test_auth_user_id, test_friend_internal_id) INTO result;
    RAISE NOTICE 'Function result: %', result;
    
END $$;