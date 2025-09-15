-- Update get_club_polls function to include vote counts per option
-- This will enable percentage calculations in the frontend

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
    options JSONB,
    total_votes BIGINT,
    created_at TIMESTAMP WITH TIME ZONE,
    closes_at TIMESTAMP WITH TIME ZONE,
    created_by_name TEXT,
    user_vote INTEGER,
    vote_counts JSONB -- New field for individual option vote counts
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
    -- Force options to be treated as JSONB and include vote counts per option
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
        uv.option_index as user_vote,
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'option_index', vc.option_index,
                    'vote_count', vc.vote_count
                ) ORDER BY vc.option_index
            ) FILTER (WHERE vc.option_index IS NOT NULL),
            '[]'::jsonb
        ) as vote_counts
    FROM book_club_polls bp
    JOIN users u ON bp.created_by = u.id
    LEFT JOIN (
        SELECT 
            poll_id,
            COUNT(*) as total_votes
        FROM book_club_poll_votes
        GROUP BY poll_id
    ) v ON bp.id = v.poll_id
    LEFT JOIN (
        SELECT 
            poll_id,
            option_index,
            COUNT(*) as vote_count
        FROM book_club_poll_votes
        GROUP BY poll_id, option_index
    ) vc ON bp.id = vc.poll_id
    LEFT JOIN book_club_poll_votes uv ON bp.id = uv.poll_id AND uv.user_id = user_uuid
    WHERE bp.club_id = club_id_param
    GROUP BY bp.id, bp.title, bp.description, bp.poll_type, bp.status, bp.options, bp.created_at, bp.closes_at, u.name, uv.option_index, v.total_votes
    ORDER BY bp.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_club_polls(UUID, UUID) TO authenticated;
