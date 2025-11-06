-- Fix reject_friend_request function to properly reject friend requests
-- This function removes or updates the friend request status to rejected

DROP FUNCTION IF EXISTS reject_friend_request(UUID, UUID);
DROP FUNCTION IF EXISTS reject_friend_request(auth_user_id UUID, requester_user_id UUID);
DROP FUNCTION IF EXISTS reject_friend_request(p_auth_user_id UUID, p_requester_user_id UUID);

CREATE OR REPLACE FUNCTION reject_friend_request(
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
    
    -- Delete the friend request (rejecting it)
    DELETE FROM friend_connections
    WHERE id = existing_connection.id;
    
    RETURN jsonb_build_object('success', true, 'message', 'Friend request rejected successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION reject_friend_request(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION reject_friend_request(UUID, UUID) TO anon;

