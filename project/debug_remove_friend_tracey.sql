-- Debug the remove friend issue with Tracey Beaker specifically
-- This will help us understand why the function can't find the friendship

-- Check William's current friends
SELECT 
    'William Current Friends' as info,
    fr.id as friendship_id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    u1.name as requester_name,
    u2.name as target_name
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9')
   OR fr.target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9');

-- Check if Tracey Beaker exists
SELECT 
    'Tracey Beaker Info' as info,
    id as internal_id,
    auth_user_id,
    name,
    username
FROM users 
WHERE id = '309f3f29-aeea-4f26-a936-8d65047dc469';

-- Check if William exists
SELECT 
    'William Info' as info,
    id as internal_id,
    auth_user_id,
    name,
    username
FROM users 
WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

-- Test the function step by step
DO $$
DECLARE
    test_auth_user_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9';
    test_friend_internal_id UUID := '309f3f29-aeea-4f26-a936-8d65047dc469';
    v_user_id UUID;
    v_friend_auth_user_id UUID;
    friendship_exists BOOLEAN;
    result JSON;
BEGIN
    RAISE NOTICE '=== DEBUGGING REMOVE FRIEND FOR TRACEY ===';
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
    
    -- Step 4: Show the actual friendship record if it exists
    IF friendship_exists THEN
        RAISE NOTICE 'Step 4 - Friendship found, showing details...';
        DECLARE
            rec RECORD;
        BEGIN
            FOR rec IN (
                SELECT fr.id, fr.requester_id, fr.target_id, fr.status, u1.name as req_name, u2.name as tar_name
                FROM friend_requests fr
                JOIN users u1 ON fr.requester_id = u1.id
                JOIN users u2 ON fr.target_id = u2.id
                WHERE ((fr.requester_id = v_user_id AND fr.target_id = test_friend_internal_id) OR 
                       (fr.requester_id = test_friend_internal_id AND fr.target_id = v_user_id))
                AND fr.status = 'accepted'
            ) LOOP
                RAISE NOTICE 'Friendship: ID=%, Requester=%(%), Target=%(%), Status=%', 
                    rec.id, rec.requester_id, rec.req_name, rec.target_id, rec.tar_name, rec.status;
            END LOOP;
        END;
    ELSE
        RAISE NOTICE 'Step 4 - No friendship found between William and Tracey';
    END IF;
    
    -- Step 5: Test the actual function
    RAISE NOTICE 'Step 5 - Testing remove_friend_by_internal_id function...';
    SELECT remove_friend_by_internal_id(test_auth_user_id, test_friend_internal_id) INTO result;
    RAISE NOTICE 'Function result: %', result;
END $$;
