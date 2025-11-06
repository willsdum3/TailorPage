-- Create a test incoming friend request
-- This will create a friend request TO the current user so we can test the function

-- Step 1: Find another user to send the request from
-- (Using one of the users from the outgoing requests)
SELECT 
    '=== AVAILABLE USERS TO CREATE TEST REQUEST ===' as info,
    id as internal_id,
    name,
    username,
    auth_user_id
FROM users
WHERE id IN (
    '8598640a-8df7-4807-8b57-3e7f3a6c7bbb',
    '99098d6a-673b-49ea-8095-e6e4e97a5231',
    '74194ae3-d05d-489f-9e9e-26d51cbaaa6d',
    '88b4421f-b441-40fe-8484-03596348fa90',
    'bc0eb657-aaf9-483d-a988-c68f79b135f9',
    '9c66d95e-f73c-4ff3-a7f9-041f9f332102'
)
ORDER BY name;

-- Step 2: Create a test incoming request
-- This creates a request FROM another user TO you
-- Replace '74194ae3-d05d-489f-9e9e-26d51cbaaa6d' with any user ID from above
INSERT INTO friend_connections (user_id, friend_id, status, created_at)
VALUES (
    '74194ae3-d05d-489f-9e9e-26d51cbaaa6d',  -- Another user's internal ID (requester)
    '8e84fd62-6b7a-40ed-9c84-e28378a1698f',  -- Your internal ID (recipient)
    'pending',
    NOW()
)
ON CONFLICT (user_id, friend_id) DO UPDATE
SET status = 'pending', created_at = NOW()
RETURNING *;

-- Step 3: Verify the request was created
SELECT 
    '=== VERIFY INCOMING REQUEST CREATED ===' as info,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    requester.name as requester_name,
    requester.username as requester_username,
    recipient.name as recipient_name
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE fc.friend_id = '8e84fd62-6b7a-40ed-9c84-e28378a1698f'  -- Your internal ID
  AND fc.user_id = '74194ae3-d05d-489f-9e9e-26d51cbaaa6d'  -- Test requester
  AND LOWER(TRIM(fc.status)) = 'pending';

-- Step 4: Test the function
SELECT 
    '=== FUNCTION RESULT (SHOULD SHOW THE REQUEST) ===' as info,
    *
FROM get_friend_requests('ee11bb62-0684-4293-a77a-d385c9a070f9');

