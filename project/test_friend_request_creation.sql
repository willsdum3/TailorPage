-- Test friend request creation and visibility
-- This will help verify that requests are created correctly and visible to recipients

-- 1. Create a test friend request
-- Replace with actual user IDs
-- User A (sender): auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9', internal_id = '8e84fd62-6b7a-40ed-9c84-e28378a1698f'
-- User B (recipient): Use another user's internal ID
DO $$
DECLARE
    sender_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9';
    sender_internal_id UUID;
    recipient_internal_id UUID := '88b4421f-b441-40fe-8484-03596348fa90';  -- Replace with actual recipient
    request_result JSONB;
BEGIN
    -- Get sender's internal ID
    SELECT id INTO sender_internal_id
    FROM users
    WHERE auth_user_id = sender_auth_id;
    
    RAISE NOTICE 'Sender internal ID: %', sender_internal_id;
    RAISE NOTICE 'Recipient internal ID: %', recipient_internal_id;
    
    -- Test the send_friend_request function
    SELECT send_friend_request(sender_auth_id, recipient_internal_id, NULL) INTO request_result;
    
    RAISE NOTICE 'Send result: %', request_result;
    
    -- Check what was created
    SELECT 
        '=== CREATED REQUEST ===' as info,
        fc.id,
        fc.user_id as requester_internal_id,
        fc.friend_id as recipient_internal_id,
        fc.status,
        requester.name as requester_name,
        requester.auth_user_id as requester_auth_id,
        recipient.name as recipient_name,
        recipient.auth_user_id as recipient_auth_id
    FROM friend_connections fc
    LEFT JOIN users requester ON fc.user_id = requester.id
    LEFT JOIN users recipient ON fc.friend_id = recipient.id
    WHERE fc.user_id = sender_internal_id
      AND fc.friend_id = recipient_internal_id
      AND LOWER(TRIM(fc.status)) = 'pending'
    ORDER BY fc.created_at DESC
    LIMIT 1;
    
    -- Test what get_friend_requests returns for the recipient
    SELECT 
        '=== RECIPIENT VIEW (get_friend_requests) ===' as info,
        *
    FROM get_friend_requests((SELECT auth_user_id FROM users WHERE id = recipient_internal_id));
END $$;

-- 2. Check all recent friend connections to see the pattern
SELECT 
    '=== ALL RECENT REQUESTS ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    fc.created_at,
    requester.name as requester_name,
    requester.auth_user_id as requester_auth_id,
    recipient.name as recipient_name,
    recipient.auth_user_id as recipient_auth_id,
    CASE 
        WHEN fc.user_id = get_user_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9') THEN 'FROM YOU'
        WHEN fc.friend_id = get_user_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9') THEN 'TO YOU'
        ELSE 'OTHER'
    END as direction
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE LOWER(TRIM(fc.status)) = 'pending'
ORDER BY fc.created_at DESC
LIMIT 10;

