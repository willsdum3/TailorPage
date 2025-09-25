-- Test the new remove_friend_by_internal_id function directly
-- This will help us see what's happening inside the function

-- First, let's test with the exact IDs from the console
DO $$
DECLARE
    test_auth_user_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'; -- William Dumbili's auth_user_id
    test_friend_internal_id UUID := 'baf44ea3-ca65-43a7-8b16-18d16370b697'; -- Pauline Dumbili's internal ID
    result JSON;
BEGIN
    -- Test the function
    SELECT remove_friend_by_internal_id(test_auth_user_id, test_friend_internal_id) INTO result;
    
    RAISE NOTICE 'Function result: %', result;
END $$;

-- Let's also check what the function should find
SELECT 
    'Current User Lookup' as test_type,
    u.id as internal_id,
    u.auth_user_id,
    u.name,
    u.username
FROM users u 
WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

SELECT 
    'Friend Lookup' as test_type,
    u.id as internal_id,
    u.auth_user_id,
    u.name,
    u.username
FROM users u 
WHERE u.id = 'baf44ea3-ca65-43a7-8b16-18d16370b697';

-- Check if friendship exists
SELECT 
    'Friendship Check' as test_type,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    u1.name as requester_name,
    u2.name as target_name
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE ((fr.requester_id = '3bd64865-45b6-4b2b-81d2-4940a8bf3200' AND fr.target_id = 'baf44ea3-ca65-43a7-8b16-18d16370b697') OR 
       (fr.requester_id = 'baf44ea3-ca65-43a7-8b16-18d16370b697' AND fr.target_id = '3bd64865-45b6-4b2b-81d2-4940a8bf3200'))
AND fr.status = 'accepted';
