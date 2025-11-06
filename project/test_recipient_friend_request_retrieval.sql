-- Test why recipients can't see their friend requests
-- Based on diagnostic results, requests exist but aren't being retrieved

-- 1. Check if the recipients have auth_user_id values
SELECT 
    '=== RECIPIENT USER INFO ===' as section,
    u.id as internal_id,
    u.auth_user_id,
    u.username,
    u.name,
    CASE 
        WHEN u.auth_user_id IS NULL THEN 'MISSING AUTH_USER_ID ✗'
        WHEN u.id IS NULL THEN 'MISSING INTERNAL_ID ✗'
        ELSE 'OK ✓'
    END as status
FROM users u
WHERE u.id IN (
    'bc0eb657-aaf9-483d-a988-c68f79b135f9',  -- user_8e84fd62
    '88b4421f-b441-40fe-8484-03596348fa90'   -- user_74194ae3
);

-- 2. Test get_user_internal_id for these recipients
SELECT 
    '=== TEST get_user_internal_id for recipients ===' as section,
    u.auth_user_id,
    u.username,
    get_user_internal_id(u.auth_user_id) as function_result,
    u.id as actual_internal_id,
    CASE 
        WHEN u.auth_user_id IS NULL THEN 'NO AUTH_USER_ID ✗'
        WHEN get_user_internal_id(u.auth_user_id) = u.id THEN 'MATCH ✓'
        WHEN get_user_internal_id(u.auth_user_id) IS NULL THEN 'FUNCTION RETURNS NULL ✗'
        ELSE 'MISMATCH ✗'
    END as validation
FROM users u
WHERE u.id IN (
    'bc0eb657-aaf9-483d-a988-c68f79b135f9',  -- user_8e84fd62
    '88b4421f-b441-40fe-8484-03596348fa90'   -- user_74194ae3
);

-- 3. Test get_friend_requests for user_8e84fd62
SELECT 
    '=== get_friend_requests for user_8e84fd62 ===' as section,
    *
FROM get_friend_requests(
    (SELECT auth_user_id FROM users WHERE id = 'bc0eb657-aaf9-483d-a988-c68f79b135f9' LIMIT 1)
);

-- 4. Test get_friend_requests for user_74194ae3
SELECT 
    '=== get_friend_requests for user_74194ae3 ===' as section,
    *
FROM get_friend_requests(
    (SELECT auth_user_id FROM users WHERE id = '88b4421f-b441-40fe-8484-03596348fa90' LIMIT 1)
);

-- 5. Manual check: What should get_friend_requests return?
-- This directly queries what the function should find
SELECT 
    '=== MANUAL CHECK: What should be returned? ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    requester.username as requester_username,
    recipient.username as recipient_username,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    CASE 
        WHEN fc.friend_id = 'bc0eb657-aaf9-483d-a988-c68f79b135f9' AND LOWER(TRIM(fc.status)) = 'pending' THEN 'SHOULD APPEAR FOR user_8e84fd62 ✓'
        WHEN fc.friend_id = '88b4421f-b441-40fe-8484-03596348fa90' AND LOWER(TRIM(fc.status)) = 'pending' THEN 'SHOULD APPEAR FOR user_74194ae3 ✓'
        ELSE 'WILL NOT APPEAR'
    END as should_appear,
    fc.created_at
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE fc.friend_id IN (
    'bc0eb657-aaf9-483d-a988-c68f79b135f9',  -- user_8e84fd62
    '88b4421f-b441-40fe-8484-03596348fa90'   -- user_74194ae3
)
AND LOWER(TRIM(fc.status)) = 'pending'
ORDER BY fc.created_at DESC;

-- 6. Check if there's a case sensitivity or whitespace issue with status
SELECT 
    '=== STATUS CHECK ===' as section,
    fc.id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    CASE 
        WHEN fc.status != LOWER(TRIM(fc.status)) THEN 'CASE/WHITESPACE ISSUE ✗'
        ELSE 'OK ✓'
    END as status_check
FROM friend_connections fc
WHERE fc.id IN (
    '0e5ba03a-ad73-4471-a2fc-f636b18f708e',  -- request to user_8e84fd62
    '6bfdc534-4fb6-468e-aef7-6fc6412228ba'   -- request to user_74194ae3
);

