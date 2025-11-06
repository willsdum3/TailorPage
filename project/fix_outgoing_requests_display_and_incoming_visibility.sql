-- Fix outgoing friend requests display and incoming requests visibility
-- This ensures usernames/avatars show correctly and all requests are visible

-- 1. Fix get_outgoing_friend_requests to ensure proper username/avatar display
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

-- 2. Fix get_friend_requests to ensure all incoming requests are visible
-- This should return ALL pending requests where the current user is the recipient
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
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    -- If user not found, return empty result instead of raising exception
    IF user_internal_id IS NULL THEN
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

-- 3. Ensure accept_friend_request properly handles status updates
-- This should already be fixed, but let's verify it uses normalized status
CREATE OR REPLACE FUNCTION accept_friend_request(
    p_auth_user_id UUID,
    p_requester_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
    accepter_internal_id UUID;
    requester_internal_id UUID;
    existing_connection RECORD;
    normalized_status TEXT;
BEGIN
    -- Get accepter's internal ID from auth_user_id
    accepter_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF accepter_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- p_requester_user_id should be the internal ID of the requester
    -- First, try to use it as internal ID
    requester_internal_id := p_requester_user_id;
    
    -- Verify requester exists (try as internal ID first)
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = requester_internal_id) THEN
        -- If not found, try to find by auth_user_id
        SELECT id INTO requester_internal_id
        FROM users
        WHERE auth_user_id = p_requester_user_id;
        
        IF requester_internal_id IS NULL THEN
            RETURN jsonb_build_object('success', false, 'error', 'Requester not found');
        END IF;
    END IF;
    
    -- Find the pending friend request (requester -> accepter)
    -- Use normalized status comparison to handle case/whitespace issues
    SELECT * INTO existing_connection
    FROM friend_connections
    WHERE user_id = requester_internal_id
      AND friend_id = accepter_internal_id
      AND LOWER(TRIM(status)) = 'pending';
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Friend request not found or already processed');
    END IF;
    
    -- Update the existing connection to accepted
    UPDATE friend_connections
    SET status = 'accepted', created_at = NOW()
    WHERE id = existing_connection.id;
    
    -- Create or update the reverse connection (accepter -> requester) to accepted
    INSERT INTO friend_connections (user_id, friend_id, status, created_at)
    VALUES (accepter_internal_id, requester_internal_id, 'accepted', NOW())
    ON CONFLICT (user_id, friend_id) 
    DO UPDATE SET status = 'accepted', created_at = NOW();
    
    RETURN jsonb_build_object('success', true, 'message', 'Friend request accepted successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION accept_friend_request(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_friend_request(UUID, UUID) TO anon;

-- 4. Diagnostic query to check all pending requests
SELECT 
    '=== ALL PENDING REQUESTS ===' as section,
    fc.id,
    requester.name as requester_name,
    requester.username as requester_username,
    requester.avatar_url as requester_avatar,
    requester.auth_user_id as requester_auth_id,
    recipient.name as recipient_name,
    recipient.username as recipient_username,
    recipient.avatar_url as recipient_avatar,
    recipient.auth_user_id as recipient_auth_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    fc.created_at
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE LOWER(TRIM(fc.status)) = 'pending'
ORDER BY fc.created_at DESC;

SELECT 'Friend request functions updated. Usernames and avatars should now display correctly.' as status;

