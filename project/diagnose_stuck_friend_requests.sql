-- Diagnose stuck friend requests
-- This will help identify why some requests are stuck

-- 1. Find all friend connections with potential issues
SELECT 
    '=== ALL FRIEND CONNECTIONS ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    fc.created_at,
    requester.name as requester_name,
    requester.username as requester_username,
    requester.auth_user_id as requester_auth_id,
    recipient.name as recipient_name,
    recipient.username as recipient_username,
    recipient.auth_user_id as recipient_auth_id,
    CASE 
        WHEN fc.status IS NULL THEN 'NULL STATUS'
        WHEN LOWER(TRIM(fc.status)) != 'pending' AND LOWER(TRIM(fc.status)) != 'accepted' AND LOWER(TRIM(fc.status)) != 'rejected' THEN 'INVALID STATUS'
        WHEN requester.id IS NULL THEN 'MISSING REQUESTER'
        WHEN recipient.id IS NULL THEN 'MISSING RECIPIENT'
        ELSE 'OK'
    END as issue_type
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
ORDER BY fc.created_at DESC;

-- 2. Find duplicate or conflicting requests
SELECT 
    '=== DUPLICATE/CONFLICTING REQUESTS ===' as section,
    LEAST(fc1.user_id, fc1.friend_id) as user1_id,
    GREATEST(fc1.user_id, fc1.friend_id) as user2_id,
    fc1.id as request1_id,
    fc1.user_id as request1_requester,
    fc1.friend_id as request1_recipient,
    fc1.status as request1_status,
    fc2.id as request2_id,
    fc2.user_id as request2_requester,
    fc2.friend_id as request2_recipient,
    fc2.status as request2_status,
    CASE 
        WHEN fc1.user_id = fc2.friend_id AND fc1.friend_id = fc2.user_id THEN 'BIDIRECTIONAL'
        WHEN fc1.user_id = fc2.user_id AND fc1.friend_id = fc2.friend_id THEN 'EXACT DUPLICATE'
        ELSE 'OTHER'
    END as conflict_type
FROM friend_connections fc1
JOIN friend_connections fc2 ON (
    (fc1.user_id = fc2.friend_id AND fc1.friend_id = fc2.user_id)
    OR (fc1.user_id = fc2.user_id AND fc1.friend_id = fc2.friend_id)
)
WHERE fc1.id != fc2.id
ORDER BY fc1.created_at DESC;

-- 3. Find requests that should be visible but aren't
-- Replace with your auth_user_id: ee11bb62-0684-4293-a77a-d385c9a070f9
-- Internal ID: 8e84fd62-6b7a-40ed-9c84-e28378a1698f
SELECT 
    '=== REQUESTS TO YOU (SHOULD BE VISIBLE) ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    fc.created_at,
    requester.name as requester_name,
    requester.username as requester_username,
    requester.auth_user_id as requester_auth_id,
    CASE 
        WHEN fc.friend_id = '8e84fd62-6b7a-40ed-9c84-e28378a1698f' AND LOWER(TRIM(fc.status)) = 'pending' THEN 'SHOULD APPEAR'
        ELSE 'WONT APPEAR'
    END as visibility_status
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
WHERE fc.friend_id = '8e84fd62-6b7a-40ed-9c84-e28378a1698f'  -- Your internal ID
ORDER BY fc.created_at DESC;

-- 4. Find requests FROM you that might be blocking new requests
SELECT 
    '=== REQUESTS FROM YOU (MIGHT BLOCK NEW REQUESTS) ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    fc.created_at,
    recipient.name as recipient_name,
    recipient.username as recipient_username,
    recipient.auth_user_id as recipient_auth_id
FROM friend_connections fc
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE fc.user_id = '8e84fd62-6b7a-40ed-9c84-e28378a1698f'  -- Your internal ID
ORDER BY fc.created_at DESC;

-- 5. Test what get_friend_requests returns
SELECT 
    '=== FUNCTION RESULT ===' as section,
    *
FROM get_friend_requests('ee11bb62-0684-4293-a77a-d385c9a070f9');

