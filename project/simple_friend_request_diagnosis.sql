-- Simple diagnostic that returns table results (not NOTICE messages)
-- This will show exactly what's wrong

-- 1. Check if recipients have auth_user_id values
SELECT 
    'RECIPIENT INFO' as check_type,
    u.id as internal_id,
    u.auth_user_id,
    u.username,
    u.name,
    CASE 
        WHEN u.auth_user_id IS NULL THEN 'NO AUTH_USER_ID ✗'
        ELSE 'HAS AUTH_USER_ID ✓'
    END as status
FROM users u
WHERE u.id IN (
    'bc0eb657-aaf9-483d-a988-c68f79b135f9',  -- user_8e84fd62
    '88b4421f-b441-40fe-8484-03596348fa90'   -- user_74194ae3
);

-- 2. Test get_user_internal_id for recipients
SELECT 
    'get_user_internal_id TEST' as check_type,
    u.username,
    u.auth_user_id as input_auth_id,
    get_user_internal_id(u.auth_user_id) as function_result,
    u.id as expected_internal_id,
    CASE 
        WHEN u.auth_user_id IS NULL THEN 'NO AUTH_USER_ID TO TEST ✗'
        WHEN get_user_internal_id(u.auth_user_id) = u.id THEN 'WORKS ✓'
        WHEN get_user_internal_id(u.auth_user_id) IS NULL THEN 'RETURNS NULL ✗'
        ELSE 'MISMATCH ✗'
    END as test_result
FROM users u
WHERE u.id IN (
    'bc0eb657-aaf9-483d-a988-c68f79b135f9',  -- user_8e84fd62
    '88b4421f-b441-40fe-8484-03596348fa90'   -- user_74194ae3
);

-- 3. Check what requests exist in database for these recipients
SELECT 
    'REQUESTS IN DATABASE' as check_type,
    fc.id,
    requester.username as requester_username,
    requester.id as requester_internal_id,
    recipient.username as recipient_username,
    recipient.id as recipient_internal_id,
    recipient.auth_user_id as recipient_auth_id,
    fc.status,
    fc.created_at,
    'SHOULD BE VISIBLE' as expected_visibility
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE fc.friend_id IN (
    'bc0eb657-aaf9-483d-a988-c68f79b135f9',  -- user_8e84fd62
    '88b4421f-b441-40fe-8484-03596348fa90'   -- user_74194ae3
)
AND LOWER(TRIM(fc.status)) = 'pending'
ORDER BY fc.created_at DESC;

-- 4. Test get_friend_requests for user_8e84fd62
SELECT 
    'get_friend_requests RESULT (user_8e84fd62)' as check_type,
    *
FROM get_friend_requests(
    (SELECT auth_user_id FROM users WHERE id = 'bc0eb657-aaf9-483d-a988-c68f79b135f9' LIMIT 1)
);

-- 5. Test get_friend_requests for user_74194ae3
SELECT 
    'get_friend_requests RESULT (user_74194ae3)' as check_type,
    *
FROM get_friend_requests(
    (SELECT auth_user_id FROM users WHERE id = '88b4421f-b441-40fe-8484-03596348fa90' LIMIT 1)
);

-- 6. If recipients don't have auth_user_id, show what needs to be fixed
SELECT 
    'FIX NEEDED' as check_type,
    u.id as internal_id,
    u.username,
    u.auth_user_id as current_auth_id,
    CASE 
        WHEN u.auth_user_id IS NULL THEN 'NEED TO SET auth_user_id FROM SUPABASE AUTH'
        ELSE 'auth_user_id EXISTS'
    END as action_needed
FROM users u
WHERE u.id IN (
    'bc0eb657-aaf9-483d-a988-c68f79b135f9',  -- user_8e84fd62
    '88b4421f-b441-40fe-8484-03596348fa90'   -- user_74194ae3
)
AND u.auth_user_id IS NULL;

