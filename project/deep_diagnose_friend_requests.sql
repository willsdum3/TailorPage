-- Deep diagnostic for friend request issues
-- This will help identify the exact problem

-- 1. Check all friend connections with detailed info
SELECT 
    '=== ALL CONNECTIONS WITH DETAILS ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status as raw_status,
    LOWER(TRIM(fc.status)) as normalized_status,
    LENGTH(fc.status) as status_length,
    fc.created_at,
    requester.name as requester_name,
    requester.username as requester_username,
    requester.auth_user_id as requester_auth_id,
    recipient.name as recipient_name,
    recipient.username as recipient_username,
    recipient.auth_user_id as recipient_auth_id,
    CASE 
        WHEN fc.status IS NULL THEN 'NULL'
        WHEN LOWER(TRIM(fc.status)) = 'pending' THEN 'PENDING'
        WHEN LOWER(TRIM(fc.status)) = 'accepted' THEN 'ACCEPTED'
        WHEN LOWER(TRIM(fc.status)) = 'rejected' THEN 'REJECTED'
        ELSE 'UNKNOWN: ' || fc.status
    END as status_category
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
ORDER BY fc.created_at DESC;

-- 2. Test the send_friend_request function logic manually
-- Replace with actual user IDs that are having issues
-- This simulates what the function does
DO $$
DECLARE
    test_requester_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9';  -- Your auth ID
    test_requester_internal_id UUID;
    test_target_internal_id UUID := '88b4421f-b441-40fe-8484-03596348fa90';  -- Replace with problematic target
    existing_connection RECORD;
    normalized_status TEXT;
BEGIN
    -- Get requester internal ID
    SELECT id INTO test_requester_internal_id
    FROM users
    WHERE auth_user_id = test_requester_auth_id;
    
    RAISE NOTICE 'Requester internal ID: %', test_requester_internal_id;
    RAISE NOTICE 'Target internal ID: %', test_target_internal_id;
    
    -- Check for existing connection (same logic as function)
    SELECT * INTO existing_connection
    FROM friend_connections
    WHERE (user_id = test_requester_internal_id AND friend_id = test_target_internal_id)
       OR (user_id = test_target_internal_id AND friend_id = test_requester_internal_id);
    
    IF FOUND THEN
        normalized_status := LOWER(TRIM(existing_connection.status));
        RAISE NOTICE 'Found existing connection:';
        RAISE NOTICE '  ID: %', existing_connection.id;
        RAISE NOTICE '  user_id: %', existing_connection.user_id;
        RAISE NOTICE '  friend_id: %', existing_connection.friend_id;
        RAISE NOTICE '  Raw status: %', existing_connection.status;
        RAISE NOTICE '  Normalized status: %', normalized_status;
        RAISE NOTICE '  Status length: %', LENGTH(existing_connection.status);
        
        IF normalized_status = 'pending' THEN
            IF existing_connection.user_id = test_requester_internal_id THEN
                RAISE NOTICE 'RESULT: Would return "Friend request already sent"';
            ELSE
                RAISE NOTICE 'RESULT: Would return "This user has already sent you a friend request"';
            END IF;
        ELSIF normalized_status = 'accepted' THEN
            RAISE NOTICE 'RESULT: Would return "You are already friends with this user"';
        ELSE
            RAISE NOTICE 'RESULT: Status is %, would allow new request', normalized_status;
        END IF;
    ELSE
        RAISE NOTICE 'No existing connection found - would allow new request';
    END IF;
END $$;

-- 3. Check for requests that should be visible but aren't
-- Replace with your auth_user_id
SELECT 
    '=== REQUESTS TO YOU (SHOULD BE IN PENDING FILTER) ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    fc.created_at,
    requester.name as requester_name,
    requester.username as requester_username,
    requester.auth_user_id as requester_auth_id,
    get_user_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9') as your_internal_id,
    (fc.friend_id = get_user_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9')) as is_to_you,
    (LOWER(TRIM(fc.status)) = 'pending') as is_pending,
    (fc.friend_id = get_user_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9') AND LOWER(TRIM(fc.status)) = 'pending') as should_appear
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
WHERE fc.friend_id = get_user_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9')
ORDER BY fc.created_at DESC;

-- 4. Check for requests FROM you (outgoing - not visible in Pending filter)
SELECT 
    '=== REQUESTS FROM YOU (OUTGOING - NOT IN PENDING FILTER) ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    fc.created_at,
    recipient.name as recipient_name,
    recipient.username as recipient_username,
    recipient.auth_user_id as recipient_auth_id,
    get_user_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9') as your_internal_id,
    (fc.user_id = get_user_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9')) as is_from_you,
    (LOWER(TRIM(fc.status)) = 'pending') as is_pending
FROM friend_connections fc
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE fc.user_id = get_user_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9')
ORDER BY fc.created_at DESC;

-- 5. Test the get_friend_requests function
SELECT 
    '=== FUNCTION RESULT ===' as section,
    *
FROM get_friend_requests('ee11bb62-0684-4293-a77a-d385c9a070f9');

-- 6. Check for any hidden characters or encoding issues in status
SELECT 
    '=== STATUS VALUE ANALYSIS ===' as section,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized,
    LENGTH(fc.status) as length,
    ASCII(SUBSTRING(fc.status FROM 1 FOR 1)) as first_char_ascii,
    COUNT(*) as count,
    STRING_AGG(fc.id::TEXT, ', ') as connection_ids
FROM friend_connections fc
GROUP BY fc.status, LOWER(TRIM(fc.status)), LENGTH(fc.status), ASCII(SUBSTRING(fc.status FROM 1 FOR 1))
ORDER BY count DESC;

