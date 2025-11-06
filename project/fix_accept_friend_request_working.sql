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

-- Test query to verify the function works
SELECT 'accept_friend_request function updated with normalized status comparison.' as status;

