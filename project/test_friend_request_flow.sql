-- Test script to verify friend request flow
-- This will help test if friend requests work correctly

-- 1. Check if there are any requests TO the current user
-- Replace with your auth_user_id: ee11bb62-0684-4293-a77a-d385c9a070f9
-- Internal ID: 8e84fd62-6b7a-40ed-9c84-e28378a1698f
SELECT 
    '=== INCOMING REQUESTS (TO YOU) ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    fc.created_at,
    requester.name as requester_name,
    requester.username as requester_username,
    requester.auth_user_id as requester_auth_id
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
WHERE fc.friend_id = '8e84fd62-6b7a-40ed-9c84-e28378a1698f'  -- Your internal ID
  AND LOWER(TRIM(fc.status)) = 'pending'
ORDER BY fc.created_at DESC;

-- 2. Check OUTGOING requests (FROM you)
SELECT 
    '=== OUTGOING REQUESTS (FROM YOU) ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    fc.created_at,
    recipient.name as recipient_name,
    recipient.username as recipient_username,
    recipient.auth_user_id as recipient_auth_id
FROM friend_connections fc
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE fc.user_id = '8e84fd62-6b7a-40ed-9c84-e28378a1698f'  -- Your internal ID
  AND LOWER(TRIM(fc.status)) = 'pending'
ORDER BY fc.created_at DESC;

-- 3. Test the function directly
SELECT 
    '=== FUNCTION RESULT ===' as section,
    *
FROM get_friend_requests('ee11bb62-0684-4293-a77a-d385c9a070f9');

-- 4. To test: Create a test friend request TO you
-- First, find another user's internal ID (replace with a real user's auth_user_id)
-- Then uncomment and run this to create a test request:
/*
DO $$
DECLARE
    test_requester_auth_id UUID := 'REPLACE_WITH_ANOTHER_USER_AUTH_ID';
    test_requester_internal_id UUID;
    current_user_internal_id UUID := '8e84fd62-6b7a-40ed-9c84-e28378a1698f';
BEGIN
    -- Get the test requester's internal ID
    SELECT id INTO test_requester_internal_id
    FROM users
    WHERE auth_user_id = test_requester_auth_id;
    
    IF test_requester_internal_id IS NULL THEN
        RAISE NOTICE 'Test requester not found';
    ELSE
        -- Create a test friend request
        INSERT INTO friend_connections (user_id, friend_id, status, created_at)
        VALUES (test_requester_internal_id, current_user_internal_id, 'pending', NOW())
        ON CONFLICT (user_id, friend_id) DO NOTHING;
        
        RAISE NOTICE 'Test friend request created from % to %', test_requester_internal_id, current_user_internal_id;
    END IF;
END $$;
*/

