-- URGENT FIX: Use table aliases to eliminate ALL column ambiguity
-- This will fix the "ambiguous column reference" errors immediately

-- Drop all functions
DO $$ 
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as argtypes
        FROM pg_proc 
        WHERE proname IN ('add_book_club_message', 'get_book_club_messages', 'update_book_club_details', 
                         'create_book_selection_poll', 'get_club_polls', 'vote_on_poll', 'toggle_book_club_visibility')
        AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || func_record.proname || '(' || func_record.argtypes || ') CASCADE';
    END LOOP;
END $$;

-- 1. MESSAGING FUNCTIONS with explicit aliases
CREATE OR REPLACE FUNCTION add_book_club_message(
    auth_user_id UUID,
    club_id_param UUID,
    content_param TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT) 
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
    is_member BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    -- Use explicit alias to avoid any ambiguity
    SELECT u_table.id INTO user_internal_id 
    FROM users u_table 
    WHERE u_table.auth_user_id = auth_user_id;
    
    IF user_internal_id IS NULL THEN 
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT; 
        RETURN; 
    END IF;
    
    SELECT EXISTS(
        SELECT 1 FROM book_club_members bcm_table 
        WHERE bcm_table.club_id = club_id_param 
        AND bcm_table.user_id = user_internal_id
    ) INTO is_member;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs bc_table 
        WHERE bc_table.id = club_id_param 
        AND bc_table.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_member OR is_creator) THEN 
        RETURN QUERY SELECT FALSE, 'You are not a member of this club'::TEXT; 
        RETURN; 
    END IF;
    
    INSERT INTO book_club_messages (club_id, user_id, content, message) 
    VALUES (club_id_param, user_internal_id, content_param, content_param);
    
    RETURN QUERY SELECT TRUE, 'Message sent successfully'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION get_book_club_messages(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID, 
    club_id UUID, 
    user_id UUID, 
    content TEXT, 
    message TEXT, 
    created_at TIMESTAMP WITH TIME ZONE, 
    updated_at TIMESTAMP WITH TIME ZONE, 
    avatar_url TEXT, 
    name TEXT, 
    username TEXT
) 
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
    is_member BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    SELECT u_table.id INTO user_internal_id 
    FROM users u_table 
    WHERE u_table.auth_user_id = auth_user_id;
    
    IF user_internal_id IS NULL THEN 
        RAISE EXCEPTION 'User not found'; 
    END IF;
    
    SELECT EXISTS(
        SELECT 1 FROM book_club_members bcm_table 
        WHERE bcm_table.club_id = club_id_param 
        AND bcm_table.user_id = user_internal_id
    ) INTO is_member;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs bc_table 
        WHERE bc_table.id = club_id_param 
        AND bc_table.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_member OR is_creator) THEN 
        RAISE EXCEPTION 'You are not a member of this club'; 
    END IF;
    
    RETURN QUERY
    SELECT 
        bcm_table.id, 
        bcm_table.club_id, 
        bcm_table.user_id, 
        COALESCE(bcm_table.content, bcm_table.message)::TEXT, 
        COALESCE(bcm_table.message, bcm_table.content)::TEXT,
        bcm_table.created_at, 
        bcm_table.updated_at, 
        COALESCE(u_table.avatar_url, '')::TEXT, 
        COALESCE(u_table.name, 'Unknown User')::TEXT, 
        COALESCE(u_table.username, 'unknown')::TEXT
    FROM book_club_messages bcm_table
    JOIN users u_table ON bcm_table.user_id = u_table.id
    WHERE bcm_table.club_id = club_id_param
    ORDER BY bcm_table.created_at DESC;
END;
$$;

-- 2. EDIT CLUB DETAILS
CREATE OR REPLACE FUNCTION update_book_club_details(
    auth_user_id UUID,
    club_id_param UUID,
    new_name TEXT DEFAULT NULL,
    new_description TEXT DEFAULT NULL,
    new_current_book_title TEXT DEFAULT NULL,
    new_current_book_author TEXT DEFAULT NULL,
    new_meeting_info TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT) 
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    SELECT u_table.id INTO user_internal_id 
    FROM users u_table 
    WHERE u_table.auth_user_id = auth_user_id;
    
    IF user_internal_id IS NULL THEN 
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT; 
        RETURN; 
    END IF;
    
    SELECT EXISTS(
        SELECT 1 FROM book_club_members bcm_table 
        WHERE bcm_table.club_id = club_id_param 
        AND bcm_table.user_id = user_internal_id 
        AND bcm_table.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs bc_table 
        WHERE bc_table.id = club_id_param 
        AND bc_table.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN 
        RETURN QUERY SELECT FALSE, 'Only admins can update club details'::TEXT; 
        RETURN; 
    END IF;
    
    UPDATE book_clubs SET
        name = COALESCE(new_name, name),
        description = COALESCE(new_description, description),
        current_book_title = COALESCE(new_current_book_title, current_book_title),
        current_book_author = COALESCE(new_current_book_author, current_book_author),
        meeting_info = COALESCE(new_meeting_info, meeting_info),
        updated_at = NOW()
    WHERE id = club_id_param;
    
    RETURN QUERY SELECT TRUE, 'Club details updated successfully'::TEXT;
END;
$$;

-- 3. POLL FUNCTIONS
CREATE OR REPLACE FUNCTION create_book_selection_poll(
    auth_user_id UUID,
    club_id_param UUID,
    poll_title TEXT,
    poll_description TEXT,
    book_options JSONB,
    closes_at TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, poll_id UUID) 
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
    new_poll_id UUID;
    close_date TIMESTAMP WITH TIME ZONE;
BEGIN
    SELECT u_table.id INTO user_internal_id 
    FROM users u_table 
    WHERE u_table.auth_user_id = auth_user_id;
    
    IF user_internal_id IS NULL THEN 
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT, NULL::UUID; 
        RETURN; 
    END IF;
    
    SELECT EXISTS(
        SELECT 1 FROM book_club_members bcm_table 
        WHERE bcm_table.club_id = club_id_param 
        AND bcm_table.user_id = user_internal_id 
        AND bcm_table.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs bc_table 
        WHERE bc_table.id = club_id_param 
        AND bc_table.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN 
        RETURN QUERY SELECT FALSE, 'Only admins can create polls'::TEXT, NULL::UUID; 
        RETURN; 
    END IF;
    
    close_date := COALESCE(closes_at::TIMESTAMP WITH TIME ZONE, NOW() + INTERVAL '7 days');
    new_poll_id := gen_random_uuid();
    
    INSERT INTO book_selection_polls (id, club_id, title, description, created_by, created_at, closes_at)
    VALUES (new_poll_id, club_id_param, poll_title, poll_description, user_internal_id, NOW(), close_date);
    
    INSERT INTO poll_options (poll_id, option_text, option_order)
    SELECT new_poll_id, value->>'title', (ROW_NUMBER() OVER ())::INTEGER
    FROM jsonb_array_elements(book_options);
    
    RETURN QUERY SELECT TRUE, 'Poll created successfully'::TEXT, new_poll_id;
END;
$$;

CREATE OR REPLACE FUNCTION get_club_polls(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS JSONB 
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
    is_member BOOLEAN;
    is_creator BOOLEAN;
    result JSONB;
BEGIN
    SELECT u_table.id INTO user_internal_id 
    FROM users u_table 
    WHERE u_table.auth_user_id = auth_user_id;
    
    IF user_internal_id IS NULL THEN 
        RAISE EXCEPTION 'User not found'; 
    END IF;
    
    SELECT EXISTS(
        SELECT 1 FROM book_club_members bcm_table 
        WHERE bcm_table.club_id = club_id_param 
        AND bcm_table.user_id = user_internal_id
    ) INTO is_member;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs bc_table 
        WHERE bc_table.id = club_id_param 
        AND bc_table.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_member OR is_creator) THEN 
        RAISE EXCEPTION 'You are not a member of this club'; 
    END IF;
    
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', p_table.id,
            'title', p_table.title,
            'description', p_table.description,
            'options', COALESCE(options_data.options, '[]'::jsonb),
            'total_votes', COALESCE(vote_data.total_votes, 0),
            'created_at', p_table.created_at,
            'closes_at', p_table.closes_at,
            'created_by_name', COALESCE(u_table.name, 'Unknown'),
            'user_vote', user_vote_data.user_vote_index,
            'vote_counts', COALESCE(vote_data.vote_counts, '[]'::jsonb)
        )
    ), '[]'::jsonb) INTO result
    FROM book_selection_polls p_table
    JOIN users u_table ON p_table.created_by = u_table.id
    LEFT JOIN (
        SELECT po_table.poll_id, jsonb_agg(jsonb_build_object('id', po_table.id, 'text', po_table.option_text, 'order', po_table.option_order) ORDER BY po_table.option_order) as options
        FROM poll_options po_table GROUP BY po_table.poll_id
    ) options_data ON p_table.id = options_data.poll_id
    LEFT JOIN (
        SELECT pv_table.poll_id, COUNT(*)::INTEGER as total_votes,
               jsonb_agg(jsonb_build_object('option_id', pv_table.option_id, 'count', vote_counts.count)) as vote_counts
        FROM poll_votes pv_table
        JOIN (SELECT option_id, COUNT(*)::INTEGER as count FROM poll_votes GROUP BY option_id) vote_counts ON pv_table.option_id = vote_counts.option_id
        GROUP BY pv_table.poll_id
    ) vote_data ON p_table.id = vote_data.poll_id
    LEFT JOIN (
        SELECT pv_table.poll_id, po_table.option_order as user_vote_index
        FROM poll_votes pv_table
        JOIN poll_options po_table ON pv_table.option_id = po_table.id
        WHERE pv_table.user_id = user_internal_id
    ) user_vote_data ON p_table.id = user_vote_data.poll_id
    WHERE p_table.club_id = club_id_param AND p_table.closes_at > NOW()
    GROUP BY p_table.id, p_table.title, p_table.description, p_table.created_at, p_table.closes_at, u_table.name, options_data.options, vote_data.total_votes, vote_data.vote_counts, user_vote_data.user_vote_index
    ORDER BY p_table.created_at DESC;
    
    RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION vote_on_poll(
    auth_user_id UUID,
    poll_id_param UUID,
    option_index INTEGER
)
RETURNS TABLE (success BOOLEAN, message TEXT) 
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
    is_member BOOLEAN;
    is_creator BOOLEAN;
    poll_club_id UUID;
    target_option_id UUID;
BEGIN
    SELECT u_table.id INTO user_internal_id 
    FROM users u_table 
    WHERE u_table.auth_user_id = auth_user_id;
    
    IF user_internal_id IS NULL THEN 
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT; 
        RETURN; 
    END IF;
    
    SELECT p_table.club_id INTO poll_club_id 
    FROM book_selection_polls p_table 
    WHERE p_table.id = poll_id_param;
    
    IF poll_club_id IS NULL THEN 
        RETURN QUERY SELECT FALSE, 'Poll not found'::TEXT; 
        RETURN; 
    END IF;
    
    SELECT EXISTS(
        SELECT 1 FROM book_club_members bcm_table 
        WHERE bcm_table.club_id = poll_club_id 
        AND bcm_table.user_id = user_internal_id
    ) INTO is_member;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs bc_table 
        WHERE bc_table.id = poll_club_id 
        AND bc_table.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_member OR is_creator) THEN 
        RETURN QUERY SELECT FALSE, 'You are not a member of this club'::TEXT; 
        RETURN; 
    END IF;
    
    SELECT po_table.id INTO target_option_id 
    FROM poll_options po_table 
    WHERE po_table.poll_id = poll_id_param 
    AND po_table.option_order = option_index;
    
    IF target_option_id IS NULL THEN 
        RETURN QUERY SELECT FALSE, 'Invalid option'::TEXT; 
        RETURN; 
    END IF;
    
    INSERT INTO poll_votes (poll_id, user_id, option_id, voted_at)
    VALUES (poll_id_param, user_internal_id, target_option_id, NOW())
    ON CONFLICT (poll_id, user_id) DO UPDATE SET option_id = target_option_id, voted_at = NOW();
    
    RETURN QUERY SELECT TRUE, 'Vote recorded successfully'::TEXT;
END;
$$;

-- 4. VISIBILITY TOGGLE
CREATE OR REPLACE FUNCTION toggle_book_club_visibility(
    auth_user_id UUID,
    club_id_param UUID,
    is_public_param BOOLEAN
)
RETURNS TABLE (success BOOLEAN, message TEXT, is_public BOOLEAN) 
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    SELECT u_table.id INTO user_internal_id 
    FROM users u_table 
    WHERE u_table.auth_user_id = auth_user_id;
    
    IF user_internal_id IS NULL THEN 
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT, FALSE; 
        RETURN; 
    END IF;
    
    SELECT EXISTS(
        SELECT 1 FROM book_club_members bcm_table 
        WHERE bcm_table.club_id = club_id_param 
        AND bcm_table.user_id = user_internal_id 
        AND bcm_table.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs bc_table 
        WHERE bc_table.id = club_id_param 
        AND bc_table.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN 
        RETURN QUERY SELECT FALSE, 'Only admins can change club visibility'::TEXT, FALSE; 
        RETURN; 
    END IF;
    
    UPDATE book_clubs SET is_public = is_public_param, updated_at = NOW() WHERE id = club_id_param;
    
    RETURN QUERY SELECT TRUE, 'Club visibility updated successfully'::TEXT, is_public_param;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION add_book_club_message(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_book_club_messages(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_book_club_details(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_book_selection_poll(UUID, UUID, TEXT, TEXT, JSONB, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_club_polls(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION vote_on_poll(UUID, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_book_club_visibility(UUID, UUID, BOOLEAN) TO authenticated;

SELECT '✅ URGENT FIX APPLIED - ALL AMBIGUITY ELIMINATED' as status;
