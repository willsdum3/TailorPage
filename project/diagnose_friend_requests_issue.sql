-- Comprehensive diagnostic for friend requests issue
-- This will help identify why friend requests aren't appearing

-- 1. Check ALL friend_connections entries
SELECT 
    '=== ALL FRIEND CONNECTIONS ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    fc.created_at,
    requester.name as requester_name,
    requester.auth_user_id as requester_auth_id,
    recipient.name as recipient_name,
    recipient.auth_user_id as recipient_auth_id
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
ORDER BY fc.created_at DESC;

-- 2. Check pending requests specifically
SELECT 
    '=== PENDING REQUESTS ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    fc.created_at,
    requester.name as requester_name,
    requester.auth_user_id as requester_auth_id,
    recipient.name as recipient_name,
    recipient.auth_user_id as recipient_auth_id
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE fc.status ILIKE '%pending%'
ORDER BY fc.created_at DESC;

-- 3. Check for requests TO the current user (where they are the recipient)
-- Replace with your auth_user_id: ee11bb62-0684-4293-a77a-d385c9a070f9
-- Internal ID: 8e84fd62-6b7a-40ed-9c84-e28378a1698f
SELECT 
    '=== REQUESTS TO CURRENT USER ===' as section,
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
    recipient.auth_user_id as recipient_auth_id,
    CASE 
        WHEN fc.friend_id = '8e84fd62-6b7a-40ed-9c84-e28378a1698f' THEN 'MATCH - This is a request TO you'
        ELSE 'NO MATCH'
    END as match_status
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE fc.friend_id = '8e84fd62-6b7a-40ed-9c84-e28378a1698f'
ORDER BY fc.created_at DESC;

-- 4. Check what the function actually returns
SELECT 
    '=== FUNCTION RESULT ===' as section,
    *
FROM get_friend_requests('ee11bb62-0684-4293-a77a-d385c9a070f9');

-- 5. Check status values in friend_connections (to see if there are variations)
SELECT 
    '=== STATUS VALUE ANALYSIS ===' as section,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized,
    LENGTH(fc.status) as status_length,
    COUNT(*) as count
FROM friend_connections fc
GROUP BY fc.status, LOWER(TRIM(fc.status)), LENGTH(fc.status)
ORDER BY count DESC;

-- 6. Test the WHERE clause logic manually
SELECT 
    '=== MANUAL WHERE CLAUSE TEST ===' as section,
    fc.id,
    fc.user_id,
    fc.friend_id,
    fc.status,
    '8e84fd62-6b7a-40ed-9c84-e28378a1698f' as current_user_internal_id,
    (fc.friend_id = '8e84fd62-6b7a-40ed-9c84-e28378a1698f') as friend_id_matches,
    (LOWER(TRIM(fc.status)) = 'pending') as status_matches,
    (fc.friend_id = '8e84fd62-6b7a-40ed-9c84-e28378a1698f' AND LOWER(TRIM(fc.status)) = 'pending') as both_match
FROM friend_connections fc
ORDER BY fc.created_at DESC;

