-- Comprehensive diagnosis of friend request delivery issues
-- This will help identify why requests aren't being received

-- 1. Find the specific users and their IDs
SELECT 
    '=== USER INFORMATION ===' as section,
    u.id as internal_id,
    u.auth_user_id,
    u.username,
    u.name,
    u.email,
    u.avatar_url,
    CASE 
        WHEN u.auth_user_id IS NULL THEN 'MISSING AUTH_USER_ID'
        WHEN u.id IS NULL THEN 'MISSING INTERNAL_ID'
        ELSE 'OK'
    END as status
FROM users u
WHERE LOWER(u.username) IN ('paulinedumbili6', 'hereistand', 'katslater', 'user_74194ae3', 'user_8e84fd62')
   OR u.id::TEXT LIKE '%74194ae3%'
   OR u.id::TEXT LIKE '%8e84fd62%'
ORDER BY u.username;

-- 2. Check ALL friend connections involving these users
SELECT 
    '=== ALL FRIEND CONNECTIONS ===' as section,
    fc.id as connection_id,
    requester.username as requester_username,
    requester.name as requester_name,
    requester.id as requester_internal_id,
    requester.auth_user_id as requester_auth_id,
    recipient.username as recipient_username,
    recipient.name as recipient_name,
    recipient.id as recipient_internal_id,
    recipient.auth_user_id as recipient_auth_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    fc.created_at,
    CASE 
        WHEN requester.id IS NULL THEN 'REQUESTER NOT FOUND'
        WHEN recipient.id IS NULL THEN 'RECIPIENT NOT FOUND'
        WHEN LOWER(TRIM(fc.status)) != 'pending' THEN 'NOT PENDING'
        ELSE 'OK'
    END as validation_status
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE LOWER(TRIM(fc.status)) = 'pending'
ORDER BY fc.created_at DESC
LIMIT 20;

-- 3. Test get_user_internal_id for paulinedumbili6
SELECT 
    '=== TEST get_user_internal_id for paulinedumbili6 ===' as section,
    u.auth_user_id,
    u.username,
    get_user_internal_id(u.auth_user_id) as function_result,
    u.id as actual_internal_id,
    CASE 
        WHEN get_user_internal_id(u.auth_user_id) = u.id THEN 'MATCH ✓'
        WHEN get_user_internal_id(u.auth_user_id) IS NULL THEN 'FUNCTION RETURNS NULL ✗'
        ELSE 'MISMATCH ✗'
    END as validation
FROM users u
WHERE LOWER(u.username) = 'paulinedumbili6'
   AND u.auth_user_id IS NOT NULL;

-- 4. Test get_user_internal_id for the problematic recipients
SELECT 
    '=== TEST get_user_internal_id for recipients ===' as section,
    u.auth_user_id,
    u.username,
    get_user_internal_id(u.auth_user_id) as function_result,
    u.id as actual_internal_id,
    CASE 
        WHEN get_user_internal_id(u.auth_user_id) = u.id THEN 'MATCH ✓'
        WHEN get_user_internal_id(u.auth_user_id) IS NULL THEN 'FUNCTION RETURNS NULL ✗'
        ELSE 'MISMATCH ✗'
    END as validation
FROM users u
WHERE (u.id::TEXT LIKE '%74194ae3%' OR u.id::TEXT LIKE '%8e84fd62%')
   AND u.auth_user_id IS NOT NULL;

-- 5. Check what get_friend_requests returns for paulinedumbili6
SELECT 
    '=== get_friend_requests for paulinedumbili6 ===' as section,
    *
FROM get_friend_requests(
    (SELECT auth_user_id FROM users WHERE LOWER(username) = 'paulinedumbili6' LIMIT 1)
);

-- 6. Check what get_outgoing_friend_requests returns for paulinedumbili6
SELECT 
    '=== get_outgoing_friend_requests for paulinedumbili6 ===' as section,
    *
FROM get_outgoing_friend_requests(
    (SELECT auth_user_id FROM users WHERE LOWER(username) = 'paulinedumbili6' LIMIT 1)
);

-- 7. Check what get_friend_requests returns for the problematic recipients
-- First, find their auth_user_ids
SELECT 
    '=== get_friend_requests for recipients ===' as section,
    recipient.username as recipient_username,
    recipient.auth_user_id,
    get_friend_requests.*
FROM users recipient
CROSS JOIN LATERAL get_friend_requests(recipient.auth_user_id) as get_friend_requests
WHERE (recipient.id::TEXT LIKE '%74194ae3%' OR recipient.id::TEXT LIKE '%8e84fd62%')
   AND recipient.auth_user_id IS NOT NULL;

-- 8. Manually check if requests exist where recipients should see them
-- This directly queries friend_connections to see what should be visible
WITH pauline_user AS (
    SELECT id, auth_user_id, username
    FROM users
    WHERE LOWER(username) = 'paulinedumbili6'
    LIMIT 1
),
recipient_users AS (
    SELECT id, auth_user_id, username
    FROM users
    WHERE id::TEXT LIKE '%74194ae3%' OR id::TEXT LIKE '%8e84fd62%'
)
SELECT 
    '=== MANUAL CHECK: Should recipients see requests? ===' as section,
    fc.id as connection_id,
    requester.username as requester_username,
    requester.id as requester_internal_id,
    recipient.username as recipient_username,
    recipient.id as recipient_internal_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    CASE 
        WHEN fc.friend_id = recipient.id AND LOWER(TRIM(fc.status)) = 'pending' THEN 'SHOULD APPEAR IN INCOMING ✓'
        ELSE 'WILL NOT APPEAR ✗'
    END as visibility_check,
    fc.created_at
FROM friend_connections fc
CROSS JOIN pauline_user pu
CROSS JOIN recipient_users ru
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE (fc.user_id = pu.id AND fc.friend_id = ru.id)
   OR (fc.user_id = ru.id AND fc.friend_id = pu.id)
ORDER BY fc.created_at DESC;

-- 9. Check for requests with wrong direction (user_id and friend_id might be swapped)
SELECT 
    '=== CHECK FOR SWAPPED USER_ID/FRIEND_ID ===' as section,
    fc.id,
    requester.username as requester_username,
    requester.id as requester_internal_id,
    recipient.username as recipient_username,
    recipient.id as recipient_internal_id,
    fc.user_id,
    fc.friend_id,
    CASE 
        WHEN fc.user_id = requester.id AND fc.friend_id = recipient.id THEN 'CORRECT DIRECTION ✓'
        WHEN fc.user_id = recipient.id AND fc.friend_id = requester.id THEN 'SWAPPED ✗'
        ELSE 'UNKNOWN'
    END as direction_check,
    fc.status,
    fc.created_at
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE LOWER(TRIM(fc.status)) = 'pending'
  AND (
      LOWER(requester.username) = 'paulinedumbili6' 
      OR LOWER(recipient.username) = 'paulinedumbili6'
      OR requester.id::TEXT LIKE '%74194ae3%'
      OR recipient.id::TEXT LIKE '%74194ae3%'
      OR requester.id::TEXT LIKE '%8e84fd62%'
      OR recipient.id::TEXT LIKE '%8e84fd62%'
  )
ORDER BY fc.created_at DESC;

