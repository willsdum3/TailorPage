-- Fix the get_club_polls function to ensure options are returned as proper JSONB
-- The issue is that options are being stored as JSONB but retrieved as strings

CREATE OR REPLACE FUNCTION get_club_polls(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    poll_type TEXT,
    status TEXT,
    options JSONB, -- Ensure this is returned as JSONB
    total_votes BIGINT,
    created_at TIMESTAMP WITH TIME ZONE,
    closes_at TIMESTAMP WITH TIME ZONE,
    created_by_name TEXT,
    user_vote INTEGER
) AS $$
DECLARE
    user_uuid UUID;
    is_member BOOLEAN;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_club_polls.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Check if user is member of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = club_id_param
        AND user_id = user_uuid
    ) INTO is_member;
    
    IF NOT is_member THEN
        RETURN;
    END IF;
    
    -- Return polls with vote counts and user's vote
    -- Force options to be treated as JSONB
    RETURN QUERY
    SELECT 
        bp.id,
        bp.title,
        bp.description,
        bp.poll_type,
        bp.status,
        bp.options::JSONB as options, -- Explicitly cast to JSONB
        COALESCE(v.total_votes, 0) as total_votes,
        bp.created_at,
        bp.closes_at,
        u.name as created_by_name,
        uv.option_index as user_vote
    FROM book_club_polls bp
    JOIN users u ON bp.created_by = u.id
    LEFT JOIN (
        SELECT 
            poll_id,
            COUNT(*) as total_votes
        FROM book_club_poll_votes
        GROUP BY poll_id
    ) v ON bp.id = v.poll_id
    LEFT JOIN book_club_poll_votes uv ON bp.id = uv.poll_id AND uv.user_id = user_uuid
    WHERE bp.club_id = club_id_param
    ORDER BY bp.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_club_polls(UUID, UUID) TO authenticated;
