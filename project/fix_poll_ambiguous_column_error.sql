-- Fix Ambiguous Column Reference Error in get_club_polls
-- The error occurs because multiple tables have 'id' columns

-- Drop the problematic function
DROP FUNCTION IF EXISTS get_club_polls(UUID, UUID) CASCADE;

-- Create the corrected get_club_polls function with explicit table references
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
    total_votes INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    closes_at TIMESTAMP WITH TIME ZONE,
    created_by_name TEXT,
    user_vote INTEGER,
    vote_counts JSONB
) AS $$
DECLARE
    user_internal_id UUID;
    club_exists BOOLEAN;
    is_member BOOLEAN;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if club exists
    SELECT EXISTS(SELECT 1 FROM book_clubs WHERE book_clubs.id = club_id_param) INTO club_exists;
    
    IF NOT club_exists THEN
        RAISE EXCEPTION 'Book club not found';
    END IF;
    
    -- Check if user is a member of the club
    SELECT EXISTS(
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.club_id = club_id_param 
        AND book_club_members.user_id = user_internal_id
    ) INTO is_member;
    
    -- Allow if user is member OR is the club creator
    IF NOT (is_member OR EXISTS(
        SELECT 1 FROM book_clubs 
        WHERE book_clubs.id = club_id_param AND book_clubs.created_by = user_internal_id
    )) THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;
    
    -- Return polls with their options and vote data - using explicit table references
    RETURN QUERY
    SELECT 
        bsp.id,
        bsp.title,
        bsp.description,
        'book_selection'::TEXT as poll_type,
        CASE 
            WHEN bsp.closes_at IS NOT NULL AND bsp.closes_at <= NOW() THEN 'closed'
            ELSE 'active'
        END::TEXT as status,
        COALESCE(
            json_agg(
                json_build_object(
                    'title', po.title,
                    'author', po.author,
                    'coverUrl', po.cover_url,
                    'description', po.description
                ) ORDER BY po.option_index
            ) FILTER (WHERE po.id IS NOT NULL),
            '[]'::json
        ) as options,
        COALESCE((
            SELECT COUNT(*)::INTEGER 
            FROM poll_votes pv 
            WHERE pv.poll_id = bsp.id
        ), 0) as total_votes,
        bsp.created_at,
        bsp.closes_at,
        u.name as created_by_name,
        COALESCE((
            SELECT pv.option_index 
            FROM poll_votes pv 
            WHERE pv.poll_id = bsp.id AND pv.user_id = user_internal_id
        ), NULL) as user_vote,
        COALESCE(
            (
                SELECT json_agg(
                    json_build_object(
                        'option_index', vote_data.option_index,
                        'vote_count', vote_data.vote_count
                    ) ORDER BY vote_data.option_index
                )
                FROM (
                    SELECT pv2.option_index, COUNT(*) as vote_count
                    FROM poll_votes pv2
                    WHERE pv2.poll_id = bsp.id
                    GROUP BY pv2.option_index
                ) vote_data
            ),
            '[]'::json
        ) as vote_counts
    FROM book_selection_polls bsp
    LEFT JOIN users u ON bsp.created_by = u.id
    LEFT JOIN poll_options po ON bsp.id = po.poll_id
    WHERE bsp.club_id = club_id_param
    GROUP BY bsp.id, bsp.title, bsp.description, bsp.created_at, bsp.closes_at, u.name
    ORDER BY bsp.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also fix the get_poll_results function to avoid similar issues
DROP FUNCTION IF EXISTS get_poll_results(UUID, UUID) CASCADE;

CREATE OR REPLACE FUNCTION get_poll_results(
    auth_user_id UUID,
    poll_id_param UUID
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    results JSONB
) AS $$
DECLARE
    user_internal_id UUID;
    poll_exists BOOLEAN;
    is_member BOOLEAN;
    poll_club_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT, NULL::JSONB;
        RETURN;
    END IF;
    
    -- Get poll details and check if it exists - using explicit table references
    SELECT bsp.club_id INTO poll_club_id
    FROM book_selection_polls bsp
    WHERE bsp.id = poll_id_param;
    
    IF poll_club_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Poll not found'::TEXT, NULL::JSONB;
        RETURN;
    END IF;
    
    -- Check if user is a member of the club
    SELECT EXISTS(
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.club_id = poll_club_id 
        AND book_club_members.user_id = user_internal_id
    ) INTO is_member;
    
    -- Allow if user is member OR is the club creator
    IF NOT (is_member OR EXISTS(
        SELECT 1 FROM book_clubs 
        WHERE book_clubs.id = poll_club_id AND book_clubs.created_by = user_internal_id
    )) THEN
        RETURN QUERY SELECT FALSE, 'User is not a member of this club'::TEXT, NULL::JSONB;
        RETURN;
    END IF;
    
    -- Return poll results - using explicit table references
    RETURN QUERY
    SELECT 
        TRUE as success,
        'Poll results retrieved successfully'::TEXT as message,
        json_build_object(
            'poll_id', bsp.id,
            'title', bsp.title,
            'description', bsp.description,
            'total_votes', (
                SELECT COUNT(*)::INTEGER 
                FROM poll_votes pv 
                WHERE pv.poll_id = bsp.id
            ),
            'options', COALESCE(
                json_agg(
                    json_build_object(
                        'option_index', po.option_index,
                        'title', po.title,
                        'author', po.author,
                        'vote_count', COALESCE(vote_counts.vote_count, 0),
                        'percentage', CASE 
                            WHEN (SELECT COUNT(*) FROM poll_votes pv2 WHERE pv2.poll_id = bsp.id) = 0 THEN 0
                            ELSE ROUND((COALESCE(vote_counts.vote_count, 0)::DECIMAL / 
                                (SELECT COUNT(*) FROM poll_votes pv3 WHERE pv3.poll_id = bsp.id)) * 100, 1)
                        END
                    ) ORDER BY po.option_index
                ) FILTER (WHERE po.id IS NOT NULL),
                '[]'::json
            )
        ) as results
    FROM book_selection_polls bsp
    LEFT JOIN poll_options po ON bsp.id = po.poll_id
    LEFT JOIN (
        SELECT pv4.option_index, COUNT(*) as vote_count
        FROM poll_votes pv4
        WHERE pv4.poll_id = poll_id_param
        GROUP BY pv4.option_index
    ) vote_counts ON po.option_index = vote_counts.option_index
    WHERE bsp.id = poll_id_param
    GROUP BY bsp.id, bsp.title, bsp.description;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also fix the vote_on_poll function
DROP FUNCTION IF EXISTS vote_on_poll(UUID, UUID, INTEGER) CASCADE;

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
    user_internal_id UUID;
    poll_exists BOOLEAN;
    poll_active BOOLEAN;
    is_member BOOLEAN;
    poll_club_id UUID;
    has_voted BOOLEAN;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT;
        RETURN;
    END IF;
    
    -- Get poll details and check if it exists - using explicit table references
    SELECT bsp.club_id, 
           CASE 
               WHEN bsp.closes_at IS NOT NULL AND bsp.closes_at <= NOW() THEN FALSE
               ELSE TRUE
           END
    INTO poll_club_id, poll_active
    FROM book_selection_polls bsp
    WHERE bsp.id = poll_id_param;
    
    IF poll_club_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Poll not found'::TEXT;
        RETURN;
    END IF;
    
    -- Check if poll is active
    IF NOT poll_active THEN
        RETURN QUERY SELECT FALSE, 'This poll is no longer active'::TEXT;
        RETURN;
    END IF;
    
    -- Check if user is a member of the club
    SELECT EXISTS(
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.club_id = poll_club_id 
        AND book_club_members.user_id = user_internal_id
    ) INTO is_member;
    
    -- Allow if user is member OR is the club creator
    IF NOT (is_member OR EXISTS(
        SELECT 1 FROM book_clubs 
        WHERE book_clubs.id = poll_club_id AND book_clubs.created_by = user_internal_id
    )) THEN
        RETURN QUERY SELECT FALSE, 'User is not a member of this club'::TEXT;
        RETURN;
    END IF;
    
    -- Check if user has already voted
    SELECT EXISTS(
        SELECT 1 FROM poll_votes 
        WHERE poll_votes.poll_id = poll_id_param AND poll_votes.user_id = user_internal_id
    ) INTO has_voted;
    
    IF has_voted THEN
        RETURN QUERY SELECT FALSE, 'You have already voted on this poll'::TEXT;
        RETURN;
    END IF;
    
    -- Check if the option index is valid
    IF NOT EXISTS(
        SELECT 1 FROM poll_options 
        WHERE poll_options.poll_id = poll_id_param AND poll_options.option_index = vote_on_poll.option_index
    ) THEN
        RETURN QUERY SELECT FALSE, 'Invalid option selected'::TEXT;
        RETURN;
    END IF;
    
    -- Record the vote
    INSERT INTO poll_votes (poll_id, user_id, option_index)
    VALUES (poll_id_param, user_internal_id, vote_on_poll.option_index);
    
    -- Return success
    RETURN QUERY SELECT TRUE, 'Vote recorded successfully'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the corrected function
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_result RECORD;
    poll_count INTEGER := 0;
BEGIN
    -- Get test data
    SELECT u.auth_user_id INTO test_user_id FROM users u WHERE u.name = 'Kat Slater' LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        RAISE NOTICE 'Testing corrected get_club_polls function...';
        RAISE NOTICE 'User: %, Club: %', test_user_id, test_club_id;
        
        -- Test the corrected function
        FOR test_result IN 
            SELECT * FROM get_club_polls(test_user_id, test_club_id)
        LOOP
            poll_count := poll_count + 1;
            RAISE NOTICE 'Poll %: id=%, title=%, status=%, total_votes=%', 
                poll_count, test_result.id, test_result.title, test_result.status, test_result.total_votes;
        END LOOP;
        
        RAISE NOTICE 'Function test complete - found % polls', poll_count;
    ELSE
        RAISE NOTICE 'No test data found';
    END IF;
END $$;

-- Show the function signatures
SELECT 
    'Corrected Poll Functions' as check_type,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name IN ('get_club_polls', 'get_poll_results', 'vote_on_poll') 
AND routine_schema = 'public'
ORDER BY routine_name;
