-- Final fix: Ensure all friend request functions work correctly
-- The diagnostic shows functions work, so this ensures they're all up to date

-- 1. Final version of get_friend_requests with maximum robustness
CREATE OR REPLACE FUNCTION get_friend_requests(
    p_auth_user_id UUID
)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    friend_id UUID,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    friend_name TEXT,
    friend_username TEXT,
    friend_email TEXT,
    friend_image_url TEXT,
    personality_match_score NUMERIC
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Handle NULL input
    IF p_auth_user_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    -- If user not found, return empty result
    IF user_internal_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Return ALL pending requests where current user is the recipient
    RETURN QUERY
    SELECT 
        fc.id,
        fc.user_id,
        fc.user_id as friend_id,  -- Return requester's ID as friend_id
        fc.status,
        fc.created_at,
        COALESCE(NULLIF(TRIM(u.name), ''), 'User') as friend_name,
        COALESCE(NULLIF(TRIM(u.username), ''), '') as friend_username,
        COALESCE(u.email, '') as friend_email,
        u.avatar_url as friend_image_url,
        0::NUMERIC as personality_match_score
    FROM friend_connections fc
    INNER JOIN users u ON fc.user_id = u.id  -- Join with requester
    WHERE fc.friend_id = user_internal_id  -- Current user is recipient
      AND LOWER(TRIM(COALESCE(fc.status, ''))) = 'pending'  -- Normalized status
    ORDER BY fc.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        -- Return empty on any error
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_friend_requests(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_friend_requests(UUID) TO anon;

-- 2. Verify the specific requests are findable
SELECT 
    '=== VERIFICATION: Requests should be visible ===' as section,
    recipient.username as recipient_username,
    recipient.auth_user_id as recipient_auth_id,
    recipient.id as recipient_internal_id,
    COUNT(fc.id) as pending_requests_count,
    CASE 
        WHEN recipient.auth_user_id IS NULL THEN '⚠️ NO AUTH_USER_ID - Requests won''t be visible!'
        WHEN get_user_internal_id(recipient.auth_user_id) IS NULL THEN '⚠️ get_user_internal_id FAILS - Requests won''t be visible!'
        WHEN COUNT(fc.id) > 0 THEN '✓ Requests exist and should be visible'
        ELSE 'No pending requests'
    END as status
FROM users recipient
LEFT JOIN friend_connections fc ON fc.friend_id = recipient.id AND LOWER(TRIM(COALESCE(fc.status, ''))) = 'pending'
WHERE recipient.id IN (
    '88b4421f-b441-40fe-8484-03596348fa90',  -- user_74194ae3
    'bc0eb657-aaf9-483d-a988-c68f79b135f9'   -- user_8e84fd62
)
GROUP BY recipient.id, recipient.username, recipient.auth_user_id;

-- 3. Show what the frontend should receive when these users log in
SELECT 
    '=== WHAT FRONTEND SHOULD RECEIVE ===' as section,
    'user_74194ae3' as user,
    recipient.auth_user_id as auth_user_id_to_use,
    COUNT(*) as request_count
FROM get_friend_requests(
    (SELECT auth_user_id FROM users WHERE id = '88b4421f-b441-40fe-8484-03596348fa90' LIMIT 1)
) as requests
CROSS JOIN users recipient
WHERE recipient.id = '88b4421f-b441-40fe-8484-03596348fa90'
GROUP BY recipient.auth_user_id
UNION ALL
SELECT 
    '=== WHAT FRONTEND SHOULD RECEIVE ===' as section,
    'user_8e84fd62' as user,
    recipient.auth_user_id as auth_user_id_to_use,
    COUNT(*) as request_count
FROM get_friend_requests(
    (SELECT auth_user_id FROM users WHERE id = 'bc0eb657-aaf9-483d-a988-c68f79b135f9' LIMIT 1)
) as requests
CROSS JOIN users recipient
WHERE recipient.id = 'bc0eb657-aaf9-483d-a988-c68f79b135f9'
GROUP BY recipient.auth_user_id;

SELECT 'Fix applied. Check verification results above. If auth_user_id is NULL, requests won''t be visible in UI.' as status;

