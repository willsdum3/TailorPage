-- Diagnose friend request issues for specific users: paulinedumbili6, hereistand, katslater
-- This script will help identify why requests aren't being received

-- 1. Find these users in the database
SELECT 
    '=== USER LOOKUP ===' as section,
    u.id as internal_id,
    u.auth_user_id,
    u.name,
    u.username,
    u.email,
    u.avatar_url,
    CASE 
        WHEN u.auth_user_id IS NULL THEN 'MISSING AUTH_USER_ID'
        WHEN u.id IS NULL THEN 'MISSING INTERNAL_ID'
        ELSE 'OK'
    END as status
FROM users u
WHERE LOWER(u.username) IN ('paulinedumbili6', 'hereistand', 'katslater')
   OR u.email LIKE '%paulinedumbili6%'
   OR u.email LIKE '%hereistand%'
   OR u.email LIKE '%katslater%'
ORDER BY u.username;

-- 2. Check all friend connections involving these users
WITH target_users AS (
    SELECT id, auth_user_id, username, name
    FROM users
    WHERE LOWER(username) IN ('paulinedumbili6', 'hereistand', 'katslater')
)
SELECT 
    '=== FRIEND CONNECTIONS FOR TARGET USERS ===' as section,
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
        WHEN fc.user_id IN (SELECT id FROM target_users) AND fc.friend_id IN (SELECT id FROM target_users) THEN 'BOTH TARGET USERS'
        WHEN fc.user_id IN (SELECT id FROM target_users) THEN 'REQUESTER IS TARGET'
        WHEN fc.friend_id IN (SELECT id FROM target_users) THEN 'RECIPIENT IS TARGET'
        ELSE 'OTHER'
    END as connection_type
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE fc.user_id IN (SELECT id FROM target_users)
   OR fc.friend_id IN (SELECT id FROM target_users)
ORDER BY fc.created_at DESC;

-- 3. Test get_user_internal_id for these users
SELECT 
    '=== TEST get_user_internal_id ===' as section,
    u.auth_user_id,
    u.username,
    get_user_internal_id(u.auth_user_id) as function_result,
    u.id as actual_internal_id,
    CASE 
        WHEN get_user_internal_id(u.auth_user_id) = u.id THEN 'MATCH'
        WHEN get_user_internal_id(u.auth_user_id) IS NULL THEN 'FUNCTION RETURNS NULL'
        ELSE 'MISMATCH'
    END as validation
FROM users u
WHERE LOWER(u.username) IN ('paulinedumbili6', 'hereistand', 'katslater')
   AND u.auth_user_id IS NOT NULL;

-- 4. Check what get_friend_requests returns for paulinedumbili6
-- (Replace with actual auth_user_id)
SELECT 
    '=== TEST get_friend_requests for paulinedumbili6 ===' as section,
    'Run: SELECT * FROM get_friend_requests((SELECT auth_user_id FROM users WHERE LOWER(username) = ''paulinedumbili6'' LIMIT 1));' as instruction;

-- 5. Check what get_outgoing_friend_requests returns for paulinedumbili6
-- (Replace with actual auth_user_id)
SELECT 
    '=== TEST get_outgoing_friend_requests for paulinedumbili6 ===' as section,
    'Run: SELECT * FROM get_outgoing_friend_requests((SELECT auth_user_id FROM users WHERE LOWER(username) = ''paulinedumbili6'' LIMIT 1));' as instruction;

-- 6. Check for requests where recipient might not be found
SELECT 
    '=== REQUESTS WITH POTENTIAL RECIPIENT ISSUES ===' as section,
    fc.id,
    requester.username as requester_username,
    requester.id as requester_internal_id,
    recipient.username as recipient_username,
    recipient.id as recipient_internal_id,
    CASE 
        WHEN recipient.id IS NULL THEN 'RECIPIENT NOT FOUND'
        WHEN requester.id IS NULL THEN 'REQUESTER NOT FOUND'
        ELSE 'OK'
    END as issue,
    fc.status,
    fc.created_at
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE (requester.id IS NULL OR recipient.id IS NULL)
   AND LOWER(TRIM(fc.status)) = 'pending'
ORDER BY fc.created_at DESC;

-- 7. Check for duplicate or conflicting requests
SELECT 
    '=== DUPLICATE REQUESTS ===' as section,
    LEAST(fc1.user_id, fc1.friend_id) as user1_id,
    GREATEST(fc1.user_id, fc1.friend_id) as user2_id,
    u1.username as user1_username,
    u2.username as user2_username,
    COUNT(*) as request_count,
    STRING_AGG(fc1.id::TEXT, ', ') as connection_ids,
    STRING_AGG(DISTINCT fc1.status, ', ') as statuses
FROM friend_connections fc1
LEFT JOIN users u1 ON LEAST(fc1.user_id, fc1.friend_id) = u1.id
LEFT JOIN users u2 ON GREATEST(fc1.user_id, fc1.friend_id) = u2.id
WHERE LOWER(TRIM(fc1.status)) = 'pending'
GROUP BY LEAST(fc1.user_id, fc1.friend_id), GREATEST(fc1.user_id, fc1.friend_id), u1.username, u2.username
HAVING COUNT(*) > 1
ORDER BY request_count DESC;

