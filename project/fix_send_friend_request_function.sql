-- Fix send_friend_request function to properly send friend requests
-- This function creates a friend request in the friend_connections table

DROP FUNCTION IF EXISTS send_friend_request(UUID, UUID);
DROP FUNCTION IF EXISTS send_friend_request(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS send_friend_request(auth_user_id UUID, target_user_id UUID);
DROP FUNCTION IF EXISTS send_friend_request(auth_user_id UUID, target_user_id UUID, message TEXT);
DROP FUNCTION IF EXISTS send_friend_request(p_auth_user_id UUID, p_target_user_id UUID);
DROP FUNCTION IF EXISTS send_friend_request(p_auth_user_id UUID, p_target_user_id UUID, p_message TEXT);

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
BEGIN
    -- Get requester's internal ID from auth_user_id
    requester_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF requester_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- p_target_user_id is the internal ID of the target user
    target_internal_id := p_target_user_id;
    
    -- Check if target user exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = target_internal_id) THEN
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
    INSERT INTO friend_connections (user_id, friend_id, status, created_at)
    VALUES (requester_internal_id, target_internal_id, 'pending', NOW())
    ON CONFLICT (user_id, friend_id) DO NOTHING;
    
    RETURN jsonb_build_object('success', true, 'message', 'Friend request sent successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION send_friend_request(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION send_friend_request(UUID, UUID, TEXT) TO anon;

