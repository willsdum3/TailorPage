-- Simple test to see what's happening with the friend lookup
-- This will help us identify the exact issue

-- Test 1: Can we find William Dumbili by his auth_user_id?
SELECT 
    'William Lookup' as test,
    id as internal_id,
    auth_user_id,
    name,
    username
FROM users 
WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

-- Test 2: Can we find Pauline Dumbili by her internal ID?
SELECT 
    'Pauline Lookup' as test,
    id as internal_id,
    auth_user_id,
    name,
    username
FROM users 
WHERE id = 'baf44ea3-ca65-43a7-8b16-18d16370b697';

-- Test 3: Check if there's a friendship between them
SELECT 
    'Friendship Check' as test,
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
        AND fr.target_id = 'baf44ea3-ca65-43a7-8b16-18d16370b697') OR 
       (fr.requester_id = 'baf44ea3-ca65-43a7-8b16-18d16370b697' 
        AND fr.target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9')))
AND fr.status = 'accepted';

-- Test 4: Check if the function exists and what it returns
SELECT 
    'Function Test' as test,
    remove_friend_by_internal_id(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
        'baf44ea3-ca65-43a7-8b16-18d16370b697'::UUID
    ) as result;
