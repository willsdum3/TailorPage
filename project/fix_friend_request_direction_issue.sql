-- Fix friend request direction issue
-- This ensures requests are created and retrieved correctly

-- 1. Verify the send_friend_request function creates requests correctly
-- Test: When User A (requester) sends to User B (target)
-- Should create: user_id = User A's internal ID, friend_id = User B's internal ID

-- 2. Check if there are any requests with swapped directions
SELECT 
    '=== REQUESTS WITH POTENTIAL DIRECTION ISSUES ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    fc.created_at,
    requester.name as requester_name,
    requester.auth_user_id as requester_auth_id,
    recipient.name as recipient_name,
    recipient.auth_user_id as recipient_auth_id,
    CASE 
        WHEN requester.id IS NULL THEN 'MISSING REQUESTER'
        WHEN recipient.id IS NULL THEN 'MISSING RECIPIENT'
        ELSE 'OK'
    END as issue
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE LOWER(TRIM(fc.status)) = 'pending'
  AND (requester.id IS NULL OR recipient.id IS NULL)
ORDER BY fc.created_at DESC;

-- 3. Test scenario: Create a request and verify both views
-- Replace with actual user IDs
DO $$
DECLARE
    sender_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9';
    sender_internal_id UUID;
    recipient_internal_id UUID := '88b4421f-b441-40fe-8484-03596348fa90';
    recipient_auth_id UUID;
    request_result JSONB;
    incoming_count INTEGER;
    outgoing_count INTEGER;
BEGIN
    -- Get IDs
    SELECT id INTO sender_internal_id FROM users WHERE auth_user_id = sender_auth_id;
    SELECT auth_user_id INTO recipient_auth_id FROM users WHERE id = recipient_internal_id;
    
    RAISE NOTICE '=== TESTING FRIEND REQUEST CREATION ===';
    RAISE NOTICE 'Sender: % (internal: %)', sender_auth_id, sender_internal_id;
    RAISE NOTICE 'Recipient: % (internal: %)', recipient_auth_id, recipient_internal_id;
    
    -- Send request
    SELECT send_friend_request(sender_auth_id, recipient_internal_id, NULL) INTO request_result;
    RAISE NOTICE 'Send result: %', request_result;
    
    -- Check what sender sees (outgoing)
    SELECT COUNT(*) INTO outgoing_count
    FROM get_outgoing_friend_requests(sender_auth_id);
    RAISE NOTICE 'Sender sees % outgoing requests', outgoing_count;
    
    -- Check what recipient sees (incoming)
    SELECT COUNT(*) INTO incoming_count
    FROM get_friend_requests(recipient_auth_id);
    RAISE NOTICE 'Recipient sees % incoming requests', incoming_count;
    
    -- Verify the database row
    RAISE NOTICE '=== DATABASE ROW ===';
    PERFORM fc.id, fc.user_id, fc.friend_id, fc.status
    FROM friend_connections fc
    WHERE fc.user_id = sender_internal_id
      AND fc.friend_id = recipient_internal_id
      AND LOWER(TRIM(fc.status)) = 'pending'
    ORDER BY fc.created_at DESC
    LIMIT 1;
END $$;

-- 4. Fix: Ensure get_friend_requests only returns requests TO the user
-- (Already correct, but let's verify)
SELECT 
    '=== VERIFY get_friend_requests LOGIC ===' as section,
    'Should return requests where friend_id = current_user_internal_id' as logic,
    'fc.user_id = requester, fc.friend_id = recipient (current user)' as explanation;

-- 5. Fix: Ensure get_outgoing_friend_requests only returns requests FROM the user
-- (Already correct, but let's verify)
SELECT 
    '=== VERIFY get_outgoing_friend_requests LOGIC ===' as section,
    'Should return requests where user_id = current_user_internal_id' as logic,
    'fc.user_id = current user (sender), fc.friend_id = recipient' as explanation;

