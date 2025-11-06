-- Fix friend request retrieval for recipients
-- Based on diagnostic: requests exist with correct direction, but recipients can't see them

-- 1. Ensure get_user_internal_id is robust
CREATE OR REPLACE FUNCTION get_user_internal_id(p_auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Direct lookup - must work for all users
    SELECT u.id INTO user_internal_id
    FROM users u 
    WHERE u.auth_user_id = p_auth_user_id;
    
    RETURN user_internal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Fix get_friend_requests to handle NULL auth_user_id cases
-- Some users might not have auth_user_id set, so we need to handle that
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
    -- Handle NULL auth_user_id
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
    -- This query MUST find all requests where fc.friend_id = user_internal_id
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
      AND LOWER(TRIM(COALESCE(fc.status, ''))) = 'pending'  -- Normalized status with NULL handling
    ORDER BY fc.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        -- Return empty on any error
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_friend_requests(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_friend_requests(UUID) TO anon;

-- 3. Also create an alternative function that can find requests by internal_id directly
-- This is a backup in case auth_user_id lookup fails
CREATE OR REPLACE FUNCTION get_friend_requests_by_internal_id(
    p_user_internal_id UUID
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
BEGIN
    -- Direct lookup by internal ID - bypasses auth_user_id lookup
    RETURN QUERY
    SELECT 
        fc.id,
        fc.user_id,
        fc.user_id as friend_id,
        fc.status,
        fc.created_at,
        COALESCE(NULLIF(TRIM(u.name), ''), 'User') as friend_name,
        COALESCE(NULLIF(TRIM(u.username), ''), '') as friend_username,
        COALESCE(u.email, '') as friend_email,
        u.avatar_url as friend_image_url,
        0::NUMERIC as personality_match_score
    FROM friend_connections fc
    INNER JOIN users u ON fc.user_id = u.id
    WHERE fc.friend_id = p_user_internal_id
      AND LOWER(TRIM(COALESCE(fc.status, ''))) = 'pending'
    ORDER BY fc.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_friend_requests_by_internal_id(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_friend_requests_by_internal_id(UUID) TO anon;

-- 4. Test the fix for the specific recipients
SELECT 
    '=== TEST FIX FOR user_8e84fd62 ===' as section,
    *
FROM get_friend_requests(
    (SELECT auth_user_id FROM users WHERE id = 'bc0eb657-aaf9-483d-a988-c68f79b135f9' LIMIT 1)
);

SELECT 
    '=== TEST FIX FOR user_74194ae3 ===' as section,
    *
FROM get_friend_requests(
    (SELECT auth_user_id FROM users WHERE id = '88b4421f-b441-40fe-8484-03596348fa90' LIMIT 1)
);

-- 5. If auth_user_id is NULL, test with internal_id directly
SELECT 
    '=== TEST WITH INTERNAL_ID (if auth_user_id is NULL) ===' as section,
    'user_8e84fd62' as username,
    *
FROM get_friend_requests_by_internal_id('bc0eb657-aaf9-483d-a988-c68f79b135f9');

SELECT 
    '=== TEST WITH INTERNAL_ID (if auth_user_id is NULL) ===' as section,
    'user_74194ae3' as username,
    *
FROM get_friend_requests_by_internal_id('88b4421f-b441-40fe-8484-03596348fa90');

SELECT 'Friend request retrieval functions updated. Run test_recipient_friend_request_retrieval.sql to verify.' as status;

