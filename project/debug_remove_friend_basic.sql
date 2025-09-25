-- Basic debug script for remove_friend_by_internal_id function
-- This will help us understand why it's returning "Friend not found"

-- Define test variables
\set test_auth_user_id 'ee11bb62-0684-4293-a77a-d385c9a070f9'  -- William's auth_user_id
\set test_friend_internal_id 'baf44ea3-ca65-43a7-8b16-18d16370b697'  -- Pauline's internal_id

-- Step 1: Get current user's internal ID
SELECT 
    'Step 1 - Current user internal ID' as step,
    id as current_user_internal_id
FROM users 
WHERE auth_user_id = :'test_auth_user_id';

-- Step 2: Get friend's auth_user_id
SELECT 
    'Step 2 - Friend auth_user_id' as step,
    auth_user_id as friend_auth_user_id
FROM users 
WHERE id = :'test_friend_internal_id';

-- Step 3: Check if friendship exists
SELECT 
    'Step 3 - Friendship exists' as step,
    EXISTS(
        SELECT 1 FROM friend_requests 
        WHERE ((requester_id = (SELECT id FROM users WHERE auth_user_id = :'test_auth_user_id') 
                AND target_id = :'test_friend_internal_id')
               OR (requester_id = :'test_friend_internal_id' 
                   AND target_id = (SELECT id FROM users WHERE auth_user_id = :'test_auth_user_id')))
        AND status = 'accepted'
    ) as friendship_exists;

-- Step 4: Show all friend_requests for these users
SELECT 
    'Step 4 - All friend_requests' as step,
    id,
    requester_id,
    target_id,
    status,
    created_at
FROM friend_requests 
WHERE (requester_id = (SELECT id FROM users WHERE auth_user_id = :'test_auth_user_id') 
       OR target_id = (SELECT id FROM users WHERE auth_user_id = :'test_auth_user_id'))
   OR (requester_id = :'test_friend_internal_id' 
       OR target_id = :'test_friend_internal_id')
ORDER BY created_at DESC;

-- Step 5: Test the actual function
SELECT 
    'Step 5 - Function result' as step,
    remove_friend_by_internal_id(:'test_auth_user_id', :'test_friend_internal_id') as result;
