-- Test the complete flow to verify everything works
-- This simulates what the frontend should see

-- 1. Verify the request exists and is correct
SELECT 
    '=== REQUEST VERIFICATION ===' as section,
    fc.id,
    requester.username as requester_username,
    requester.id as requester_internal_id,
    requester.auth_user_id as requester_auth_id,
    recipient.username as recipient_username,
    recipient.id as recipient_internal_id,
    recipient.auth_user_id as recipient_auth_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    fc.created_at
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE fc.id IN (
    '6bfdc534-4fb6-468e-aef7-6fc6412228ba',  -- request to user_74194ae3
    '0e5ba03a-ad73-4471-a2fc-f636b18f708e'   -- request to user_8e84fd62
);

-- 2. Test what get_friend_requests returns for user_74194ae3
-- This should match what the frontend receives
SELECT 
    '=== FRONTEND SHOULD SEE THIS (user_74194ae3) ===' as section,
    *
FROM get_friend_requests(
    (SELECT auth_user_id FROM users WHERE id = '88b4421f-b441-40fe-8484-03596348fa90' LIMIT 1)
);

-- 3. Test what get_friend_requests returns for user_8e84fd62
SELECT 
    '=== FRONTEND SHOULD SEE THIS (user_8e84fd62) ===' as section,
    *
FROM get_friend_requests(
    (SELECT auth_user_id FROM users WHERE id = 'bc0eb657-aaf9-483d-a988-c68f79b135f9' LIMIT 1)
);

-- 4. Check if there are any duplicate or conflicting requests
SELECT 
    '=== CHECK FOR DUPLICATES ===' as section,
    LEAST(fc1.user_id, fc1.friend_id) as user1_id,
    GREATEST(fc1.user_id, fc1.friend_id) as user2_id,
    COUNT(*) as connection_count,
    STRING_AGG(fc1.id::TEXT, ', ') as connection_ids,
    STRING_AGG(DISTINCT fc1.status, ', ') as statuses
FROM friend_connections fc1
WHERE (fc1.user_id = '99098d6a-673b-49ea-8095-e6e4e97a5231' AND fc1.friend_id IN ('88b4421f-b441-40fe-8484-03596348fa90', 'bc0eb657-aaf9-483d-a988-c68f79b135f9'))
   OR (fc1.friend_id = '99098d6a-673b-49ea-8095-e6e4e97a5231' AND fc1.user_id IN ('88b4421f-b441-40fe-8484-03596348fa90', 'bc0eb657-aaf9-483d-a988-c68f79b135f9'))
GROUP BY LEAST(fc1.user_id, fc1.friend_id), GREATEST(fc1.user_id, fc1.friend_id)
HAVING COUNT(*) > 1;

