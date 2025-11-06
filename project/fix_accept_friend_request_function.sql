-- Fix accept_friend_request function to properly accept friend requests
-- This function accepts a friend request and updates the friend_connections table

DROP FUNCTION IF EXISTS accept_friend_request(UUID, UUID);
DROP FUNCTION IF EXISTS accept_friend_request(auth_user_id UUID, requester_user_id UUID);
DROP FUNCTION IF EXISTS accept_friend_request(p_auth_user_id UUID, p_requester_user_id UUID);

CREATE OR REPLACE FUNCTION accept_friend_request(
    p_auth_user_id UUID,
    p_requester_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
    accepter_internal_id UUID;
    requester_internal_id UUID;
    existing_connection RECORD;
BEGIN
    -- Get accepter's internal ID from auth_user_id
    accepter_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF accepter_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- p_requester_user_id is the internal ID of the requester (from get_friend_requests)
    requester_internal_id := p_requester_user_id;
    
    -- Check if requester exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = requester_internal_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Requester not found');
    END IF;
    
    -- Find the pending friend request (requester -> accepter)
    SELECT * INTO existing_connection
    FROM friend_connections
    WHERE user_id = requester_internal_id
      AND friend_id = accepter_internal_id
      AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Friend request not found or already processed');
    END IF;
    
    -- Update the existing connection to accepted
    UPDATE friend_connections
    SET status = 'accepted'
    WHERE id = existing_connection.id;
    
    -- Create or update the reverse connection (accepter -> requester) to accepted
    INSERT INTO friend_connections (user_id, friend_id, status, created_at)
    VALUES (accepter_internal_id, requester_internal_id, 'accepted', NOW())
    ON CONFLICT (user_id, friend_id) 
    DO UPDATE SET status = 'accepted';
    
    RETURN jsonb_build_object('success', true, 'message', 'Friend request accepted successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION accept_friend_request(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_friend_request(UUID, UUID) TO anon;

