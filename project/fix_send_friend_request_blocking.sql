-- Update send_friend_request to check for blocking before allowing friend requests

-- Find and update the send_friend_request function
-- This assumes the function exists in fix_friend_request_delivery_comprehensive.sql or similar

DROP FUNCTION IF EXISTS send_friend_request(UUID, UUID, TEXT);

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

    -- Check if requester is blocked by target
    IF EXISTS (
        SELECT 1
        FROM user_blocks ub
        WHERE ub.blocker_id = target_internal_id
          AND ub.blocked_id = requester_internal_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'You cannot send a friend request to this user. You have been blocked.');
    END IF;

    -- Check if requester has blocked the target
    IF EXISTS (
        SELECT 1
        FROM user_blocks ub
        WHERE ub.blocker_id = requester_internal_id
          AND ub.blocked_id = target_internal_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'You cannot send a friend request to this user. You have blocked them.');
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
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;

GRANT EXECUTE ON FUNCTION send_friend_request(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION send_friend_request(UUID, UUID, TEXT) TO anon;

