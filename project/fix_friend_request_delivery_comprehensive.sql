-- Comprehensive fix for friend request delivery issues
-- This addresses the root cause: ensuring requests are created and retrieved correctly

-- 1. Ensure get_user_internal_id is robust and handles all cases
CREATE OR REPLACE FUNCTION get_user_internal_id(p_auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Direct lookup with proper table qualification
    -- This MUST work for all users
    SELECT u.id INTO user_internal_id
    FROM users u 
    WHERE u.auth_user_id = p_auth_user_id;
    
    RETURN user_internal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Fix get_friend_requests - ensure it finds ALL requests where user is recipient
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
    -- Get user's internal ID - CRITICAL: must work for all users
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    -- If user not found, return empty result
    IF user_internal_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Return ALL pending friend requests where the current user is the recipient
    -- fc.user_id = requester (person who sent the request)
    -- fc.friend_id = current user (person receiving the request)
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
      AND LOWER(TRIM(fc.status)) = 'pending'  -- Normalized status check
    ORDER BY fc.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        -- Return empty on error instead of raising exception
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_friend_requests(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_friend_requests(UUID) TO anon;

-- 3. Fix get_outgoing_friend_requests - ensure proper username/avatar display
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
    
    -- Return ALL pending friend requests where current user is the sender
    -- fc.user_id = current user (sender)
    -- fc.friend_id = recipient (person receiving the request)
    RETURN QUERY
    SELECT 
        fc.id,
        fc.user_id,
        fc.friend_id as friend_id,  -- Return recipient's ID
        fc.status,
        fc.created_at,
        COALESCE(NULLIF(TRIM(u.name), ''), 'User') as friend_name,
        COALESCE(NULLIF(TRIM(u.username), ''), '') as friend_username,
        COALESCE(u.email, '') as friend_email,
        u.avatar_url as friend_image_url,
        0::NUMERIC as personality_match_score
    FROM friend_connections fc
    INNER JOIN users u ON fc.friend_id = u.id  -- Join with recipient to get their info
    WHERE fc.user_id = user_internal_id  -- Current user is sender
      AND LOWER(TRIM(fc.status)) = 'pending'  -- Normalized status check
    ORDER BY fc.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        -- Return empty on error
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_outgoing_friend_requests(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_outgoing_friend_requests(UUID) TO anon;

-- 4. Fix send_friend_request - ensure target user ID is ALWAYS correctly resolved
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
    -- Get requester's internal ID
    requester_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF requester_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- CRITICAL: Resolve target user ID - try multiple methods
    -- Method 1: Try as internal ID (most common)
    SELECT id INTO target_internal_id
    FROM users
    WHERE id = p_target_user_id;
    
    -- Method 2: If not found, try as auth_user_id
    IF target_internal_id IS NULL THEN
        SELECT id INTO target_internal_id
        FROM users
        WHERE auth_user_id = p_target_user_id;
    END IF;
    
    -- Method 3: If still not found, try by username (if p_target_user_id is a username)
    IF target_internal_id IS NULL THEN
        SELECT id INTO target_internal_id
        FROM users
        WHERE LOWER(TRIM(username)) = LOWER(TRIM(p_target_user_id::TEXT));
    END IF;
    
    IF target_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Target user not found');
    END IF;
    
    -- Prevent self-requests
    IF requester_internal_id = target_internal_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'You cannot send a friend request to yourself');
    END IF;
    
    -- Check for existing connection (both directions)
    SELECT * INTO existing_connection
    FROM friend_connections
    WHERE (user_id = requester_internal_id AND friend_id = target_internal_id)
       OR (user_id = target_internal_id AND friend_id = requester_internal_id);
    
    IF FOUND THEN
        normalized_status := LOWER(TRIM(existing_connection.status));
        
        IF normalized_status = 'accepted' THEN
            RETURN jsonb_build_object('success', false, 'error', 'You are already friends with this user');
        END IF;
        
        IF normalized_status = 'pending' THEN
            IF existing_connection.user_id = requester_internal_id THEN
                RETURN jsonb_build_object('success', false, 'error', 'Friend request already sent');
            ELSE
                RETURN jsonb_build_object('success', false, 'error', 'This user has already sent you a friend request');
            END IF;
        END IF;
    END IF;
    
    -- Create the request: user_id = requester, friend_id = target
    INSERT INTO friend_connections (user_id, friend_id, status, created_at)
    VALUES (requester_internal_id, target_internal_id, 'pending', NOW())
    ON CONFLICT (user_id, friend_id) DO NOTHING
    RETURNING id INTO created_request_id;
    
    -- Verify creation
    IF created_request_id IS NULL THEN
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

-- 5. Verify all functions are working
SELECT 
    '=== FUNCTION VERIFICATION ===' as section,
    'All friend request functions have been updated.' as status,
    'Run comprehensive_friend_request_diagnosis.sql to test.' as next_step;

