-- Fix existing broken friend requests in the database
-- This script identifies and fixes requests that aren't being delivered

-- 1. Find requests where friend_id might be an auth_user_id instead of internal_id
-- These would be broken requests
SELECT 
    '=== POTENTIALLY BROKEN REQUESTS ===' as section,
    fc.id,
    fc.user_id,
    fc.friend_id,
    requester.username as requester_username,
    requester.id as requester_internal_id,
    recipient.username as recipient_username,
    recipient.id as recipient_internal_id,
    CASE 
        WHEN recipient.id IS NULL AND EXISTS (
            SELECT 1 FROM users u WHERE u.auth_user_id = fc.friend_id
        ) THEN 'FRIEND_ID IS AUTH_USER_ID (BROKEN)'
        WHEN requester.id IS NULL THEN 'REQUESTER NOT FOUND'
        WHEN recipient.id IS NULL THEN 'RECIPIENT NOT FOUND'
        ELSE 'OK'
    END as issue_type,
    fc.status,
    fc.created_at
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE LOWER(TRIM(fc.status)) = 'pending'
  AND (recipient.id IS NULL OR requester.id IS NULL)
ORDER BY fc.created_at DESC;

-- 2. Fix broken requests where friend_id is actually an auth_user_id
-- This updates friend_id from auth_user_id to the correct internal_id
UPDATE friend_connections fc
SET friend_id = (
    SELECT u.id 
    FROM users u 
    WHERE u.auth_user_id = fc.friend_id
    LIMIT 1
)
WHERE fc.friend_id NOT IN (SELECT id FROM users)
  AND EXISTS (SELECT 1 FROM users u WHERE u.auth_user_id = fc.friend_id)
  AND LOWER(TRIM(fc.status)) = 'pending';

-- 3. Fix broken requests where user_id is actually an auth_user_id
UPDATE friend_connections fc
SET user_id = (
    SELECT u.id 
    FROM users u 
    WHERE u.auth_user_id = fc.user_id
    LIMIT 1
)
WHERE fc.user_id NOT IN (SELECT id FROM users)
  AND EXISTS (SELECT 1 FROM users u WHERE u.auth_user_id = fc.user_id)
  AND LOWER(TRIM(fc.status)) = 'pending';

-- 4. Delete orphaned requests that can't be fixed (where user doesn't exist at all)
DELETE FROM friend_connections
WHERE id IN (
    SELECT fc.id
    FROM friend_connections fc
    LEFT JOIN users requester ON fc.user_id = requester.id
    LEFT JOIN users recipient ON fc.friend_id = recipient.id
    WHERE (requester.id IS NULL OR recipient.id IS NULL)
      AND LOWER(TRIM(fc.status)) = 'pending'
      AND NOT EXISTS (SELECT 1 FROM users u WHERE u.auth_user_id = fc.user_id)
      AND NOT EXISTS (SELECT 1 FROM users u WHERE u.auth_user_id = fc.friend_id)
);

-- 5. Verify the fixes worked
SELECT 
    '=== VERIFICATION: All requests should now be valid ===' as section,
    COUNT(*) as total_pending_requests,
    COUNT(*) FILTER (WHERE requester.id IS NOT NULL AND recipient.id IS NOT NULL) as valid_requests,
    COUNT(*) FILTER (WHERE requester.id IS NULL OR recipient.id IS NULL) as invalid_requests
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE LOWER(TRIM(fc.status)) = 'pending';

-- 6. Show all fixed requests
SELECT 
    '=== ALL FIXED REQUESTS ===' as section,
    fc.id,
    requester.username as requester_username,
    requester.id as requester_internal_id,
    recipient.username as recipient_username,
    recipient.id as recipient_internal_id,
    fc.status,
    fc.created_at,
    CASE 
        WHEN requester.id IS NOT NULL AND recipient.id IS NOT NULL THEN 'VALID ✓'
        ELSE 'STILL INVALID ✗'
    END as status_check
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE LOWER(TRIM(fc.status)) = 'pending'
ORDER BY fc.created_at DESC;

SELECT 'Broken friend requests have been fixed.' as status;

