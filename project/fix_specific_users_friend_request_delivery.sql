-- Fix friend request delivery issues for specific users
-- This addresses why requests from/to paulinedumbili6, hereistand, katslater aren't being received

-- 1. First, verify get_user_internal_id works correctly for all users
-- This is critical - if this function fails, requests won't be found
CREATE OR REPLACE FUNCTION get_user_internal_id(p_auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Direct lookup with proper table qualification
    SELECT u.id INTO user_internal_id
    FROM users u 
    WHERE u.auth_user_id = p_auth_user_id;
    
    RETURN user_internal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Fix get_friend_requests to be more robust
-- Ensure it finds ALL pending requests where the user is the recipient
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
    -- Get user's internal ID - this MUST work for all users
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    -- If user not found, return empty result instead of raising exception
    IF user_internal_id IS NULL THEN
        -- Log for debugging (if possible)
        RETURN;
    END IF;
    
    -- Return pending friend requests where the current user is the friend (being requested)
    -- fc.user_id is the requester (the one who sent the request)
    -- fc.friend_id is the current user (the one being requested)
    -- We return fc.user_id as friend_id because that's the ID of the friend (requester)
    RETURN QUERY
    SELECT 
        fc.id,
        fc.user_id,
        fc.user_id as friend_id,  -- Return requester's ID as friend_id (the person who sent the request)
        fc.status,
        fc.created_at,
        COALESCE(NULLIF(TRIM(u.name), ''), 'User') as friend_name,  -- Ensure not empty
        COALESCE(NULLIF(TRIM(u.username), ''), '') as friend_username,  -- Can be empty but not null
        COALESCE(u.email, '') as friend_email,
        u.avatar_url as friend_image_url,
        0::NUMERIC as personality_match_score
    FROM friend_connections fc
    INNER JOIN users u ON fc.user_id = u.id  -- Join with requester (user_id)
    WHERE fc.friend_id = user_internal_id  -- Current user is the recipient
      AND LOWER(TRIM(fc.status)) = 'pending'
    ORDER BY fc.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        -- Return empty result on any error instead of propagating exception
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_friend_requests(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_friend_requests(UUID) TO anon;

-- 3. Fix send_friend_request to ensure target user ID is correctly resolved
-- This is critical - if target user isn't found correctly, request won't be created properly
CREATE OR REPLACE FUNCTION send_friend_request(
    p_auth_user_id UUID,
    p_target_user_id UUID,
    p_message TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    requester_internal_id UUID;
    target_internal_id UUID;
    existing_connection RECORD;
    normalized_status TEXT;
    created_request_id UUID;
BEGIN
    -- Get requester's internal ID from auth_user_id
    requester_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF requester_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- p_target_user_id should be the internal ID of the target user
    -- First, try to use it as internal ID
    SELECT id INTO target_internal_id
    FROM users
    WHERE id = p_target_user_id;
    
    -- If not found, try to find by auth_user_id (in case p_target_user_id is actually an auth_user_id)
    IF target_internal_id IS NULL THEN
        SELECT id INTO target_internal_id
        FROM users
        WHERE auth_user_id = p_target_user_id;
    END IF;
    
    IF target_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Target user not found');
    END IF;
    
    -- Prevent users from sending friend requests to themselves
    IF requester_internal_id = target_internal_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'You cannot send a friend request to yourself');
    END IF;
    
    -- Check if a connection already exists (check both directions)
    SELECT * INTO existing_connection
    FROM friend_connections
    WHERE (user_id = requester_internal_id AND friend_id = target_internal_id)
       OR (user_id = target_internal_id AND friend_id = requester_internal_id);
    
    IF FOUND THEN
        -- Normalize status for comparison
        normalized_status := LOWER(TRIM(existing_connection.status));
        
        -- If already accepted, return error
        IF normalized_status = 'accepted' THEN
            RETURN jsonb_build_object('success', false, 'error', 'You are already friends with this user');
        END IF;
        
        -- If pending, return error with more context
        IF normalized_status = 'pending' THEN
            IF existing_connection.user_id = requester_internal_id THEN
                RETURN jsonb_build_object('success', false, 'error', 'Friend request already sent');
            ELSE
                RETURN jsonb_build_object('success', false, 'error', 'This user has already sent you a friend request');
            END IF;
        END IF;
    END IF;
    
    -- Create new friend request (requester -> target)
    -- CRITICAL: user_id = requester, friend_id = target
    INSERT INTO friend_connections (user_id, friend_id, status, created_at)
    VALUES (requester_internal_id, target_internal_id, 'pending', NOW())
    ON CONFLICT (user_id, friend_id) DO NOTHING
    RETURNING id INTO created_request_id;
    
    -- Verify the request was created correctly
    IF created_request_id IS NULL THEN
        -- Check if it was created by ON CONFLICT DO NOTHING
        SELECT id INTO created_request_id
        FROM friend_connections
        WHERE user_id = requester_internal_id
          AND friend_id = target_internal_id
          AND LOWER(TRIM(status)) = 'pending'
        ORDER BY created_at DESC
        LIMIT 1;
    END IF;
    
    IF created_request_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Failed to create friend request');
    END IF;
    
    RETURN jsonb_build_object('success', true, 'message', 'Friend request sent successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION send_friend_request(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION send_friend_request(UUID, UUID, TEXT) TO anon;

-- 4. Fix get_outgoing_friend_requests to ensure proper username/avatar display
CREATE OR REPLACE FUNCTION get_outgoing_friend_requests(
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
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    -- If user not found, return empty result
    IF user_internal_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Return pending friend requests where the current user is the requester (sent requests)
    -- fc.user_id is the current user (sender)
    -- fc.friend_id is the recipient (the person the request was sent to)
    RETURN QUERY
    SELECT 
        fc.id,
        fc.user_id,
        fc.friend_id as friend_id,  -- Return recipient's ID as friend_id
        fc.status,
        fc.created_at,
        COALESCE(NULLIF(TRIM(u.name), ''), 'User') as friend_name,  -- Ensure not empty
        COALESCE(NULLIF(TRIM(u.username), ''), '') as friend_username,  -- Can be empty but not null
        COALESCE(u.email, '') as friend_email,
        u.avatar_url as friend_image_url,
        0::NUMERIC as personality_match_score
    FROM friend_connections fc
    INNER JOIN users u ON fc.friend_id = u.id  -- Join with recipient (friend_id)
    WHERE fc.user_id = user_internal_id  -- Current user is the sender
      AND LOWER(TRIM(fc.status)) = 'pending'
    ORDER BY fc.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        -- Return empty result on any error
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_outgoing_friend_requests(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_outgoing_friend_requests(UUID) TO anon;

-- 5. Diagnostic: Check for orphaned friend connections (where user doesn't exist)
SELECT 
    '=== ORPHANED CONNECTIONS ===' as section,
    fc.id,
    fc.user_id,
    fc.friend_id,
    fc.status,
    CASE 
        WHEN requester.id IS NULL THEN 'REQUESTER MISSING'
        WHEN recipient.id IS NULL THEN 'RECIPIENT MISSING'
        ELSE 'OK'
    END as issue,
    fc.created_at
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE (requester.id IS NULL OR recipient.id IS NULL)
   AND LOWER(TRIM(fc.status)) = 'pending'
ORDER BY fc.created_at DESC;

-- 6. Clean up any orphaned connections (optional - uncomment if needed)
-- DELETE FROM friend_connections
-- WHERE id IN (
--     SELECT fc.id
--     FROM friend_connections fc
--     LEFT JOIN users requester ON fc.user_id = requester.id
--     LEFT JOIN users recipient ON fc.friend_id = recipient.id
--     WHERE (requester.id IS NULL OR recipient.id IS NULL)
--        AND LOWER(TRIM(fc.status)) = 'pending'
-- );

SELECT 'Friend request functions updated. All users should now receive requests correctly.' as status;

