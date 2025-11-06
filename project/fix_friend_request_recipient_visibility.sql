-- Fix friend request recipient visibility issue
-- Ensure requests appear correctly for both sender and recipient

-- 1. Verify the send_friend_request function creates requests with correct direction
-- When User A sends to User B: user_id = User A's internal ID, friend_id = User B's internal ID

-- 2. Add logging/validation to send_friend_request to ensure correct creation
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
    -- Verify it exists and get it
    SELECT id INTO target_internal_id
    FROM users
    WHERE id = p_target_user_id;
    
    IF target_internal_id IS NULL THEN
        -- Try to find by auth_user_id if p_target_user_id is actually an auth_user_id
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

-- 3. Verify get_friend_requests returns requests TO the user (incoming)
-- This should return requests where friend_id = current_user_internal_id
-- (The current user is the recipient)
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
        COALESCE(u.name, 'User') as friend_name,
        COALESCE(u.username, '') as friend_username,
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

-- 4. Verify get_outgoing_friend_requests returns requests FROM the user (outgoing)
-- This should return requests where user_id = current_user_internal_id
-- (The current user is the sender)
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
    -- fc.friend_id is the recipient
    RETURN QUERY
    SELECT 
        fc.id,
        fc.user_id,
        fc.friend_id as friend_id,  -- Return recipient's ID as friend_id
        fc.status,
        fc.created_at,
        COALESCE(u.name, 'User') as friend_name,
        COALESCE(u.username, '') as friend_username,
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

-- 5. Diagnostic query to check for misdirected requests
SELECT 
    '=== DIAGNOSTIC: Check for misdirected requests ===' as section,
    fc.id,
    requester.name as requester_name,
    requester.auth_user_id as requester_auth_id,
    recipient.name as recipient_name,
    recipient.auth_user_id as recipient_auth_id,
    fc.status,
    fc.created_at,
    CASE 
        WHEN fc.user_id IS NULL OR fc.friend_id IS NULL THEN 'MISSING USER'
        WHEN requester.id IS NULL THEN 'MISSING REQUESTER'
        WHEN recipient.id IS NULL THEN 'MISSING RECIPIENT'
        ELSE 'OK'
    END as validation_status
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE LOWER(TRIM(fc.status)) = 'pending'
ORDER BY fc.created_at DESC
LIMIT 20;

SELECT 'Friend request functions updated. Verify requests are created with correct direction.' as status;

