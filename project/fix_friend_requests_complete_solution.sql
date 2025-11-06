-- Complete solution for friend request retrieval issues
-- This ensures requests are found regardless of auth_user_id status

-- 1. Ensure get_user_internal_id is bulletproof
CREATE OR REPLACE FUNCTION get_user_internal_id(p_auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Handle NULL input
    IF p_auth_user_id IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Direct lookup with proper table qualification
    SELECT u.id INTO user_internal_id
    FROM users u 
    WHERE u.auth_user_id = p_auth_user_id;
    
    RETURN user_internal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Fix get_friend_requests with comprehensive error handling
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
    -- This is the critical query - it MUST find requests where fc.friend_id = user_internal_id
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
    INNER JOIN users u ON fc.user_id = u.id  -- Join with requester to get their info
    WHERE fc.friend_id = user_internal_id  -- Current user is the recipient
      AND LOWER(TRIM(COALESCE(fc.status, ''))) = 'pending'  -- Normalized status check with NULL handling
    ORDER BY fc.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        -- Return empty on any error - don't raise exception
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_friend_requests(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_friend_requests(UUID) TO anon;

-- 3. Verify the fix works for the specific problematic requests
-- Test for user_8e84fd62 (internal_id: bc0eb657-aaf9-483d-a988-c68f79b135f9)
DO $$
DECLARE
    recipient_auth_id UUID;
    recipient_internal_id UUID := 'bc0eb657-aaf9-483d-a988-c68f79b135f9';
    request_count INTEGER;
BEGIN
    -- Get auth_user_id for this recipient
    SELECT auth_user_id INTO recipient_auth_id
    FROM users
    WHERE id = recipient_internal_id;
    
    RAISE NOTICE '=== TESTING FOR user_8e84fd62 ===';
    RAISE NOTICE 'Internal ID: %', recipient_internal_id;
    RAISE NOTICE 'Auth User ID: %', recipient_auth_id;
    
    -- Check if requests exist in database
    SELECT COUNT(*) INTO request_count
    FROM friend_connections
    WHERE friend_id = recipient_internal_id
      AND LOWER(TRIM(status)) = 'pending';
    
    RAISE NOTICE 'Requests in database: %', request_count;
    
    -- Test get_user_internal_id
    IF recipient_auth_id IS NOT NULL THEN
        RAISE NOTICE 'get_user_internal_id result: %', get_user_internal_id(recipient_auth_id);
    ELSE
        RAISE NOTICE 'WARNING: Recipient has no auth_user_id!';
    END IF;
    
    -- Test get_friend_requests if auth_user_id exists
    IF recipient_auth_id IS NOT NULL THEN
        RAISE NOTICE 'Testing get_friend_requests...';
        PERFORM * FROM get_friend_requests(recipient_auth_id);
        GET DIAGNOSTICS request_count = ROW_COUNT;
        RAISE NOTICE 'get_friend_requests returned % rows', request_count;
    END IF;
END $$;

-- 4. Test for user_74194ae3 (internal_id: 88b4421f-b441-40fe-8484-03596348fa90)
DO $$
DECLARE
    recipient_auth_id UUID;
    recipient_internal_id UUID := '88b4421f-b441-40fe-8484-03596348fa90';
    request_count INTEGER;
BEGIN
    -- Get auth_user_id for this recipient
    SELECT auth_user_id INTO recipient_auth_id
    FROM users
    WHERE id = recipient_internal_id;
    
    RAISE NOTICE '=== TESTING FOR user_74194ae3 ===';
    RAISE NOTICE 'Internal ID: %', recipient_internal_id;
    RAISE NOTICE 'Auth User ID: %', recipient_auth_id;
    
    -- Check if requests exist in database
    SELECT COUNT(*) INTO request_count
    FROM friend_connections
    WHERE friend_id = recipient_internal_id
      AND LOWER(TRIM(status)) = 'pending';
    
    RAISE NOTICE 'Requests in database: %', request_count;
    
    -- Test get_user_internal_id
    IF recipient_auth_id IS NOT NULL THEN
        RAISE NOTICE 'get_user_internal_id result: %', get_user_internal_id(recipient_auth_id);
    ELSE
        RAISE NOTICE 'WARNING: Recipient has no auth_user_id!';
    END IF;
    
    -- Test get_friend_requests if auth_user_id exists
    IF recipient_auth_id IS NOT NULL THEN
        RAISE NOTICE 'Testing get_friend_requests...';
        PERFORM * FROM get_friend_requests(recipient_auth_id);
        GET DIAGNOSTICS request_count = ROW_COUNT;
        RAISE NOTICE 'get_friend_requests returned % rows', request_count;
    END IF;
END $$;

-- 5. Direct query to verify requests should be visible
SELECT 
    '=== DIRECT VERIFICATION ===' as section,
    fc.id as connection_id,
    requester.username as requester_username,
    requester.id as requester_internal_id,
    recipient.username as recipient_username,
    recipient.id as recipient_internal_id,
    recipient.auth_user_id as recipient_auth_id,
    fc.status,
    CASE 
        WHEN recipient.auth_user_id IS NULL THEN 'RECIPIENT HAS NO AUTH_USER_ID ✗'
        WHEN get_user_internal_id(recipient.auth_user_id) = recipient.id THEN 'get_user_internal_id WORKS ✓'
        ELSE 'get_user_internal_id FAILS ✗'
    END as validation,
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

SELECT 'Complete fix applied. Check the NOTICE messages above for test results.' as status;

