-- Fix get_friend_connections function to return friend_image_url
-- This function retrieves all friend connections for a user

DROP FUNCTION IF EXISTS get_friend_connections(UUID);
DROP FUNCTION IF EXISTS get_friend_connections(auth_user_id UUID);
DROP FUNCTION IF EXISTS get_friend_connections(p_auth_user_id UUID);

CREATE OR REPLACE FUNCTION get_friend_connections(
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
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Return friend connections with friend details, excluding blocked users
    RETURN QUERY
    SELECT 
        fc.id,
        fc.user_id,
        fc.friend_id,
        fc.status,
        fc.created_at,
        u.name as friend_name,
        u.username as friend_username,
        u.email as friend_email,
        u.avatar_url as friend_image_url,
        COALESCE(0, 0)::NUMERIC as personality_match_score
    FROM friend_connections fc
    JOIN users u ON fc.friend_id = u.id
    WHERE fc.user_id = user_internal_id
      AND NOT EXISTS (
          SELECT 1
          FROM user_blocks ub
          WHERE (ub.blocker_id = user_internal_id AND ub.blocked_id = fc.friend_id)
             OR (ub.blocker_id = fc.friend_id AND ub.blocked_id = user_internal_id)
      )
    ORDER BY fc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_friend_connections(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_friend_connections(UUID) TO anon;

