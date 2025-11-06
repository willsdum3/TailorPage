-- Diagnostic script to investigate friend request flow issues
-- Run this after accepting a friend request to see what's happening

-- 1. Check all friend connections with their statuses
SELECT 
    '=== ALL FRIEND CONNECTIONS ===' as section,
    fc.id,
    requester.name as requester_name,
    requester.username as requester_username,
    requester.auth_user_id as requester_auth_id,
    recipient.name as recipient_name,
    recipient.username as recipient_username,
    recipient.auth_user_id as recipient_auth_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    fc.created_at,
    CASE 
        WHEN LOWER(TRIM(fc.status)) = 'pending' THEN 'PENDING'
        WHEN LOWER(TRIM(fc.status)) = 'accepted' THEN 'ACCEPTED'
        WHEN LOWER(TRIM(fc.status)) = 'rejected' THEN 'REJECTED'
        ELSE 'UNKNOWN'
    END as status_category
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
ORDER BY fc.created_at DESC
LIMIT 20;

-- 2. Check for duplicate or conflicting connections
SELECT 
    '=== POTENTIAL DUPLICATES ===' as section,
    LEAST(fc1.user_id, fc1.friend_id) as user1_id,
    GREATEST(fc1.user_id, fc1.friend_id) as user2_id,
    COUNT(*) as connection_count,
    STRING_AGG(DISTINCT fc1.status, ', ') as statuses,
    STRING_AGG(fc1.id::TEXT, ', ') as connection_ids
FROM friend_connections fc1
GROUP BY LEAST(fc1.user_id, fc1.friend_id), GREATEST(fc1.user_id, fc1.friend_id)
HAVING COUNT(*) > 1
ORDER BY connection_count DESC;

-- 3. Test get_friend_requests for a specific user (replace with actual auth_user_id)
-- This shows what incoming requests a user should see
SELECT 
    '=== TEST get_friend_requests ===' as section,
    'Replace p_auth_user_id with actual user auth_user_id to test' as note;

-- 4. Test get_outgoing_friend_requests for a specific user (replace with actual auth_user_id)
-- This shows what outgoing requests a user should see
SELECT 
    '=== TEST get_outgoing_friend_requests ===' as section,
    'Replace p_auth_user_id with actual user auth_user_id to test' as note;

-- 5. Check for requests that might be stuck in wrong status
SELECT 
    '=== REQUESTS WITH ISSUES ===' as section,
    fc.id,
    requester.name as requester_name,
    recipient.name as recipient_name,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    CASE 
        WHEN LOWER(TRIM(fc.status)) NOT IN ('pending', 'accepted', 'rejected') THEN 'INVALID STATUS'
        WHEN fc.status != LOWER(TRIM(fc.status)) THEN 'CASE MISMATCH'
        WHEN TRIM(fc.status) != fc.status THEN 'WHITESPACE ISSUE'
        ELSE 'OK'
    END as issue_type,
    fc.created_at
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE LOWER(TRIM(fc.status)) NOT IN ('pending', 'accepted', 'rejected')
   OR fc.status != LOWER(TRIM(fc.status))
   OR TRIM(fc.status) != fc.status
ORDER BY fc.created_at DESC;

