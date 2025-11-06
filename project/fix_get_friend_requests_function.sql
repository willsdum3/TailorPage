-- Fix get_friend_requests function to return friend_image_url
-- This function retrieves pending friend requests for a user

DROP FUNCTION IF EXISTS get_friend_requests(UUID);
DROP FUNCTION IF EXISTS get_friend_requests(auth_user_id UUID);
DROP FUNCTION IF EXISTS get_friend_requests(p_auth_user_id UUID);

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
    INNER JOIN users u ON fc.user_id = u.id
    WHERE fc.friend_id = user_internal_id
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

