-- Add poll management functions for book clubs
-- This enables creating, voting on, and managing polls

-- Function to create a book selection poll
CREATE OR REPLACE FUNCTION create_book_selection_poll(
    auth_user_id UUID,
    club_id_param UUID,
    poll_title TEXT,
    poll_description TEXT,
    book_options JSONB,
    closes_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    poll_id UUID
) AS $$
DECLARE
    user_uuid UUID;
    is_admin BOOLEAN;
    new_poll_id UUID;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = create_book_selection_poll.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN QUERY SELECT false, 'User not found', NULL::UUID;
        RETURN;
    END IF;
    
    -- Check if user is admin of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = create_book_selection_poll.club_id_param 
        AND user_id = user_uuid
        AND role = 'admin'
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RETURN QUERY SELECT false, 'Only admins can create polls', NULL::UUID;
        RETURN;
    END IF;
    
    -- Create the poll
    INSERT INTO book_club_polls (club_id, created_by, title, description, poll_type, options, closes_at)
    VALUES (club_id_param, user_uuid, poll_title, poll_description, 'book_selection', book_options, closes_at)
    RETURNING id INTO new_poll_id;
    
    RETURN QUERY SELECT true, 'Poll created successfully', new_poll_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to vote on a poll
CREATE OR REPLACE FUNCTION vote_on_poll(
    auth_user_id UUID,
    poll_id_param UUID,
    option_index INTEGER
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_uuid UUID;
    poll_exists BOOLEAN;
    poll_active BOOLEAN;
    option_count INTEGER;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = vote_on_poll.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN QUERY SELECT false, 'User not found';
        RETURN;
    END IF;
    
    -- Check if poll exists and is active
    SELECT EXISTS(SELECT 1 FROM book_club_polls WHERE id = poll_id_param) INTO poll_exists;
    IF NOT poll_exists THEN
        RETURN QUERY SELECT false, 'Poll not found';
        RETURN;
    END IF;
    
    SELECT (status = 'active') INTO poll_active
    FROM book_club_polls 
    WHERE id = poll_id_param;
    
    IF NOT poll_active THEN
        RETURN QUERY SELECT false, 'Poll is not active';
        RETURN;
    END IF;
    
    -- Check if option index is valid
    SELECT jsonb_array_length(options) INTO option_count
    FROM book_club_polls 
    WHERE id = poll_id_param;
    
    IF option_index < 0 OR option_index >= option_count THEN
        RETURN QUERY SELECT false, 'Invalid option selected';
        RETURN;
    END IF;
    
    -- Insert or update vote
    INSERT INTO book_club_poll_votes (poll_id, user_id, option_index)
    VALUES (poll_id_param, user_uuid, option_index)
    ON CONFLICT (poll_id, user_id)
    DO UPDATE SET option_index = EXCLUDED.option_index, created_at = NOW();
    
    RETURN QUERY SELECT true, 'Vote recorded successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get poll results
CREATE OR REPLACE FUNCTION get_poll_results(
    auth_user_id UUID,
    poll_id_param UUID
)
RETURNS TABLE (
    poll_id UUID,
    title TEXT,
    description TEXT,
    poll_type TEXT,
    status TEXT,
    options JSONB,
    votes JSONB,
    total_votes BIGINT,
    created_at TIMESTAMP WITH TIME ZONE,
    closes_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_uuid UUID;
    is_member BOOLEAN;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_poll_results.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Check if user is member of the club
    SELECT EXISTS(
        SELECT 1 FROM book_club_polls bp
        JOIN club_memberships cm ON bp.club_id = cm.club_id
        WHERE bp.id = poll_id_param
        AND cm.user_id = user_uuid
    ) INTO is_member;
    
    IF NOT is_member THEN
        RETURN;
    END IF;
    
    -- Return poll with vote counts
    RETURN QUERY
    SELECT 
        bp.id,
        bp.title,
        bp.description,
        bp.poll_type,
        bp.status,
        bp.options,
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'option_index', v.option_index,
                    'vote_count', v.vote_count
                ) ORDER BY v.option_index
            ) FILTER (WHERE v.option_index IS NOT NULL),
            '[]'::jsonb
        ) as votes,
        COALESCE(SUM(v.vote_count), 0) as total_votes,
        bp.created_at,
        bp.closes_at
    FROM book_club_polls bp
    LEFT JOIN (
        SELECT 
            poll_id,
            option_index,
            COUNT(*) as vote_count
        FROM book_club_poll_votes
        WHERE poll_id = poll_id_param
        GROUP BY poll_id, option_index
    ) v ON bp.id = v.poll_id
    WHERE bp.id = poll_id_param
    GROUP BY bp.id, bp.title, bp.description, bp.poll_type, bp.status, bp.options, bp.created_at, bp.closes_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all polls for a club
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
    RETURN QUERY
    SELECT 
        bp.id,
        bp.title,
        bp.description,
        bp.poll_type,
        bp.status,
        bp.options,
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
GRANT EXECUTE ON FUNCTION create_book_selection_poll(UUID, UUID, TEXT, TEXT, JSONB, TIMESTAMP WITH TIME ZONE) TO authenticated;
GRANT EXECUTE ON FUNCTION vote_on_poll(UUID, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_poll_results(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_club_polls(UUID, UUID) TO authenticated;
